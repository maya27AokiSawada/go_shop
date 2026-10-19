"use strict";

// 家族特典クーポン
//
// - Premium（purchaseType: subscribe）のユーザーに固有のクーポンを1つ発行する。
// - クーポンを入力したユーザーが、発行者のグループのどれかに参加していれば
//   （入力時のみ確認）、発行者の Premium が有効な間 Premium 同等（purchaseType: family）になる。
// - 同時に特典を受けられるのは5人まで。発行者は家族を解除して枠を空けられる。
//
// データ:
//   familyCoupons/{code}         { sponsorUid, createdAt }                    （クライアント読み書き不可）
//   users/{sponsorUid}.familyCoupon  { code, members: {uid: {displayName, grantedAt}}, createdAt }
//   users/{memberUid}.familyBenefit  { sponsorUid, sponsorDisplayName, grantedAt }
//   （familyCoupon / familyBenefit / purchaseType は Security Rules でクライアント書き込み不可）

const crypto = require("crypto");
const { Timestamp } = require("firebase-admin/firestore");

const FAMILY_MEMBER_LIMIT = 5;
const SPONSOR_PURCHASE_TYPE = "subscribe";
const FAMILY_PURCHASE_TYPE = "family";
const FREE_PURCHASE_TYPE = "free";
// 読み間違えやすい文字（I, O, 0, 1）を除く
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const CODE_LENGTH = 8;
const MAX_ISSUE_ATTEMPTS = 5;

class FamilyCouponError extends Error {
  /**
   * @param {string} code HttpsError のコード
   * @param {string} reason クライアントが文言を選ぶための理由
   */
  constructor(code, reason) {
    super(reason);
    this.name = "FamilyCouponError";
    this.code = code;
    this.reason = reason;
  }
}

function generateCouponCode(randomInt = crypto.randomInt) {
  let raw = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    raw += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
  }
  return `${raw.slice(0, 4)}-${raw.slice(4)}`;
}

/** 入力されたクーポンを XXXX-XXXX に正規化する。形式が不正なら null。 */
function normalizeCouponCode(input) {
  if (typeof input !== "string") return null;
  const raw = input.toUpperCase().replace(/[^A-Z0-9]/g, "");
  if (raw.length !== CODE_LENGTH) return null;
  for (const ch of raw) {
    if (!CODE_ALPHABET.includes(ch)) return null;
  }
  return `${raw.slice(0, 4)}-${raw.slice(4)}`;
}

function isFreeType(purchaseType) {
  return !purchaseType || purchaseType === FREE_PURCHASE_TYPE;
}

function membersOf(familyCoupon) {
  return { ...(familyCoupon?.members || {}) };
}

function withoutMember(familyCoupon, uid) {
  const members = membersOf(familyCoupon);
  delete members[uid];
  return { ...familyCoupon, members };
}

function couponView(familyCoupon) {
  return {
    code: familyCoupon.code,
    memberLimit: FAMILY_MEMBER_LIMIT,
  };
}

/** Premium ユーザーのクーポンを返す（未発行なら発行する） */
async function issueFamilyCoupon({
  db,
  uid,
  now = new Date(),
  generateCode = generateCouponCode,
}) {
  const userRef = db.collection("users").doc(uid);
  const createdAt = Timestamp.fromDate(now);

  for (let attempt = 0; attempt < MAX_ISSUE_ATTEMPTS; attempt++) {
    const result = await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      const user = userSnap.exists ? userSnap.data() : {};
      if (user.purchaseType !== SPONSOR_PURCHASE_TYPE) {
        throw new FamilyCouponError("failed-precondition", "not-premium");
      }
      if (user.familyCoupon?.code) return couponView(user.familyCoupon);

      const code = generateCode();
      const couponRef = db.collection("familyCoupons").doc(code);
      const couponSnap = await tx.get(couponRef);
      if (couponSnap.exists) return null; // 衝突したら作り直す

      const familyCoupon = { code, members: {}, createdAt };
      tx.set(couponRef, { sponsorUid: uid, createdAt });
      tx.update(userRef, { familyCoupon });
      return couponView(familyCoupon);
    });
    if (result) return result;
  }
  throw new FamilyCouponError("internal", "issue-failed");
}

/** uid が sponsorUid の参加しているグループのどれかに参加しているか */
async function isInSponsorGroup(db, uid, sponsorUid) {
  const groups = await db
    .collection("SharedGroups")
    .where("allowedUid", "array-contains", uid)
    .get();
  return groups.docs.some((doc) => {
    const group = doc.data();
    if (group.isDeleted === true) return false;
    const allowed = Array.isArray(group.allowedUid) ? group.allowedUid : [];
    return group.ownerUid === sponsorUid || allowed.includes(sponsorUid);
  });
}

/** クーポンを入力して家族特典を受け取る */
async function redeemFamilyCoupon({ db, uid, code, now = new Date() }) {
  const normalized = normalizeCouponCode(code);
  if (!normalized) {
    throw new FamilyCouponError("invalid-argument", "invalid-code");
  }

  const couponSnap = await db.collection("familyCoupons").doc(normalized).get();
  if (!couponSnap.exists) {
    throw new FamilyCouponError("not-found", "invalid-code");
  }
  const sponsorUid = couponSnap.data().sponsorUid;
  if (sponsorUid === uid) {
    throw new FamilyCouponError("failed-precondition", "own-coupon");
  }
  // 家族の範囲は入力時のみ確認する（後でグループを抜けても特典は続く）
  if (!(await isInSponsorGroup(db, uid, sponsorUid))) {
    throw new FamilyCouponError("permission-denied", "not-family");
  }

  const grantedAt = Timestamp.fromDate(now);
  const sponsorRef = db.collection("users").doc(sponsorUid);
  const memberRef = db.collection("users").doc(uid);

  return db.runTransaction(async (tx) => {
    const sponsorSnap = await tx.get(sponsorRef);
    const memberSnap = await tx.get(memberRef);
    const sponsor = sponsorSnap.exists ? sponsorSnap.data() : {};
    if (sponsor.purchaseType !== SPONSOR_PURCHASE_TYPE) {
      throw new FamilyCouponError("failed-precondition", "sponsor-inactive");
    }
    const familyCoupon = sponsor.familyCoupon;
    if (!familyCoupon || familyCoupon.code !== normalized) {
      throw new FamilyCouponError("not-found", "invalid-code");
    }
    const members = membersOf(familyCoupon);
    if (members[uid]) {
      throw new FamilyCouponError("already-exists", "already-member");
    }
    if (Object.keys(members).length >= FAMILY_MEMBER_LIMIT) {
      throw new FamilyCouponError("resource-exhausted", "limit-reached");
    }
    if (!memberSnap.exists) {
      throw new FamilyCouponError("failed-precondition", "no-profile");
    }
    const member = memberSnap.data();

    // 別の家族特典からの乗り換えは、その特典が停止中のときだけ認める
    const oldSponsorUid = member.familyBenefit?.sponsorUid;
    let oldSponsorRef = null;
    let oldSponsor = null;
    if (oldSponsorUid && oldSponsorUid !== sponsorUid) {
      if (member.purchaseType === FAMILY_PURCHASE_TYPE) {
        throw new FamilyCouponError("failed-precondition", "other-benefit-active");
      }
      oldSponsorRef = db.collection("users").doc(oldSponsorUid);
      const oldSponsorSnap = await tx.get(oldSponsorRef);
      oldSponsor = oldSponsorSnap.exists ? oldSponsorSnap.data() : null;
    }

    members[uid] = { displayName: member.displayName || "", grantedAt };
    tx.update(sponsorRef, { familyCoupon: { ...familyCoupon, members } });

    if (oldSponsor?.familyCoupon?.members?.[uid]) {
      tx.update(oldSponsorRef, {
        familyCoupon: withoutMember(oldSponsor.familyCoupon, uid),
      });
    }

    const memberUpdate = {
      familyBenefit: {
        sponsorUid,
        sponsorDisplayName: sponsor.displayName || "",
        grantedAt,
      },
    };
    // 自分で課金している場合は自分の課金を優先する
    if (isFreeType(member.purchaseType)) {
      memberUpdate.purchaseType = FAMILY_PURCHASE_TYPE;
    }
    tx.update(memberRef, memberUpdate);

    return {
      sponsorDisplayName: sponsor.displayName || "",
      purchaseType: memberUpdate.purchaseType || member.purchaseType,
    };
  });
}

/** 発行者が家族の特典を解除する（枠が空く） */
async function removeFamilyMember({ db, sponsorUid, memberUid, deleteField }) {
  if (typeof memberUid !== "string" || memberUid.length === 0) {
    throw new FamilyCouponError("invalid-argument", "invalid-member");
  }
  const sponsorRef = db.collection("users").doc(sponsorUid);
  const memberRef = db.collection("users").doc(memberUid);

  await db.runTransaction(async (tx) => {
    const sponsorSnap = await tx.get(sponsorRef);
    const memberSnap = await tx.get(memberRef);
    const sponsor = sponsorSnap.exists ? sponsorSnap.data() : {};
    if (!sponsor.familyCoupon?.members?.[memberUid]) {
      throw new FamilyCouponError("not-found", "invalid-member");
    }
    tx.update(sponsorRef, {
      familyCoupon: withoutMember(sponsor.familyCoupon, memberUid),
    });

    const member = memberSnap.exists ? memberSnap.data() : null;
    if (member?.familyBenefit?.sponsorUid === sponsorUid) {
      const memberUpdate = { familyBenefit: deleteField() };
      if (member.purchaseType === FAMILY_PURCHASE_TYPE) {
        memberUpdate.purchaseType = FREE_PURCHASE_TYPE;
      }
      tx.update(memberRef, memberUpdate);
    }
  });
}

/**
 * users/{uid} の書き込みに合わせて家族特典を同期する（Firestore トリガー）
 * - 発行者の Premium が有効/無効になったら、家族の purchaseType を family/free にする
 * - 家族自身の課金が切れて free になったら、発行者が有効なら family に戻す
 * - アカウント削除時はクーポンと特典のつながりを片付ける
 */
async function syncFamilyBenefitsOnUserWrite({
  db,
  uid,
  before,
  after,
  deleteField,
}) {
  if (!after) {
    await cleanupDeletedUser({ db, uid, before, deleteField });
    return;
  }

  const wasSponsorActive = before?.purchaseType === SPONSOR_PURCHASE_TYPE;
  const isSponsorActive = after.purchaseType === SPONSOR_PURCHASE_TYPE;
  if (wasSponsorActive !== isSponsorActive && after.familyCoupon) {
    for (const memberUid of Object.keys(membersOf(after.familyCoupon))) {
      const memberRef = db.collection("users").doc(memberUid);
      await db.runTransaction(async (tx) => {
        const memberSnap = await tx.get(memberRef);
        if (!memberSnap.exists) return;
        const member = memberSnap.data();
        if (member.familyBenefit?.sponsorUid !== uid) return;
        if (isSponsorActive && isFreeType(member.purchaseType)) {
          tx.update(memberRef, { purchaseType: FAMILY_PURCHASE_TYPE });
        } else if (
          !isSponsorActive && member.purchaseType === FAMILY_PURCHASE_TYPE
        ) {
          tx.update(memberRef, { purchaseType: FREE_PURCHASE_TYPE });
        }
      });
    }
  }

  const sponsorUid = after.familyBenefit?.sponsorUid;
  const becameFree =
    before?.purchaseType !== after.purchaseType &&
    isFreeType(after.purchaseType);
  if (sponsorUid && becameFree) {
    const memberRef = db.collection("users").doc(uid);
    const sponsorRef = db.collection("users").doc(sponsorUid);
    await db.runTransaction(async (tx) => {
      const sponsorSnap = await tx.get(sponsorRef);
      const memberSnap = await tx.get(memberRef);
      if (!sponsorSnap.exists || !memberSnap.exists) return;
      const sponsor = sponsorSnap.data();
      const member = memberSnap.data();
      if (
        sponsor.purchaseType === SPONSOR_PURCHASE_TYPE &&
        sponsor.familyCoupon?.members?.[uid] &&
        member.familyBenefit?.sponsorUid === sponsorUid &&
        isFreeType(member.purchaseType)
      ) {
        tx.update(memberRef, { purchaseType: FAMILY_PURCHASE_TYPE });
      }
    });
  }
}

async function cleanupDeletedUser({ db, uid, before, deleteField }) {
  if (!before) return;

  if (before.familyCoupon) {
    for (const memberUid of Object.keys(membersOf(before.familyCoupon))) {
      const memberRef = db.collection("users").doc(memberUid);
      await db.runTransaction(async (tx) => {
        const memberSnap = await tx.get(memberRef);
        if (!memberSnap.exists) return;
        const member = memberSnap.data();
        if (member.familyBenefit?.sponsorUid !== uid) return;
        const memberUpdate = { familyBenefit: deleteField() };
        if (member.purchaseType === FAMILY_PURCHASE_TYPE) {
          memberUpdate.purchaseType = FREE_PURCHASE_TYPE;
        }
        tx.update(memberRef, memberUpdate);
      });
    }
    if (before.familyCoupon.code) {
      await db.collection("familyCoupons").doc(before.familyCoupon.code).delete();
    }
  }

  const sponsorUid = before.familyBenefit?.sponsorUid;
  if (sponsorUid) {
    const sponsorRef = db.collection("users").doc(sponsorUid);
    await db.runTransaction(async (tx) => {
      const sponsorSnap = await tx.get(sponsorRef);
      if (!sponsorSnap.exists) return;
      const sponsor = sponsorSnap.data();
      if (!sponsor.familyCoupon?.members?.[uid]) return;
      tx.update(sponsorRef, {
        familyCoupon: withoutMember(sponsor.familyCoupon, uid),
      });
    });
  }
}

module.exports = {
  FAMILY_MEMBER_LIMIT,
  FamilyCouponError,
  generateCouponCode,
  issueFamilyCoupon,
  normalizeCouponCode,
  redeemFamilyCoupon,
  removeFamilyMember,
  syncFamilyBenefitsOnUserWrite,
};
