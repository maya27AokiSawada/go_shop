import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../utils/appLog.dart';

/// 繝｡繝ｼ繝ｫ騾∽ｿ｡繧ｹ繝・・繧ｿ繧ｹ繧堤｢ｺ隱阪☆繧九せ繧ｯ繝ｪ繝励ヨ
void main() async {
  Log.info('剥 繝｡繝ｼ繝ｫ騾∽ｿ｡繧ｹ繝・・繧ｿ繧ｹ繝√ぉ繝・け髢句ｧ・..\n');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Log.info('笨・Firebase蛻晄悄蛹門ｮ御ｺ・n');

    final firestore = FirebaseFirestore.instance;

    // mail繧ｳ繝ｬ繧ｯ繧ｷ繝ｧ繝ｳ縺ｮ蜈ｨ繝峨く繝･繝｡繝ｳ繝医ｒ蜿門ｾ・
    final mailSnapshot = await firestore
        .collection('mail')
        .orderBy('delivery.startTime', descending: true)
        .limit(10)
        .get();

    if (mailSnapshot.docs.isEmpty) {
      Log.e('笶・mail繧ｳ繝ｬ繧ｯ繧ｷ繝ｧ繝ｳ縺ｫ繝峨く繝･繝｡繝ｳ繝医′縺ゅｊ縺ｾ縺帙ｓ');
      return;
    }

    Log.i('透 譛霑代・繝｡繝ｼ繝ｫ騾∽ｿ｡繧ｹ繝・・繧ｿ繧ｹ (譛譁ｰ10莉ｶ):\n');
    Log.i('=' * 80);

    for (var doc in mailSnapshot.docs) {
      final data = doc.data();
      Log.i('\n鐙 繝峨く繝･繝｡繝ｳ繝・D: ${doc.id}');
      Log.i('   螳帛・: ${data['to']}');
      Log.i('   莉ｶ蜷・ ${data['message']?['subject'] ?? 'N/A'}');

      if (data['delivery'] != null) {
        final delivery = data['delivery'] as Map<String, dynamic>;
        Log.i('   驟埼∫憾諷・ ${delivery['state'] ?? 'PENDING'}');
        Log.i('   髢句ｧ区凾蛻ｻ: ${delivery['startTime']?.toDate() ?? 'N/A'}');
        Log.i('   邨ゆｺ・凾蛻ｻ: ${delivery['endTime']?.toDate() ?? 'N/A'}');
        Log.i('   隧ｦ陦悟屓謨ｰ: ${delivery['attempts'] ?? 0}');

        if (delivery['error'] != null) {
          Log.e('   笶・繧ｨ繝ｩ繝ｼ諠・ｱ:');
          final error = delivery['error'];
          if (error is String) {
            Log.i('      $error');
          } else if (error is Map) {
            error.forEach((key, value) {
              Log.i('      $key: $value');
            });
          }
        }

        if (delivery['info'] != null) {
          final info = delivery['info'];
          if (info is Map) {
            Log.i('   邃ｹ・・ 霑ｽ蜉諠・ｱ:');
            info.forEach((key, value) {
              Log.i('      $key: $value');
            });
          }
        }
      } else {
        Log.i('   驟埼∫憾諷・ 竢ｳ PENDING (蜃ｦ逅・ｾ・■)');
      }

      Log.i('   ${'-' * 76}');
    }

    Log.i('\n${'=' * 80}');
    Log.i('\n庁 繝医Λ繝悶Ν繧ｷ繝･繝ｼ繝・ぅ繝ｳ繧ｰ:');
    Log.i('1. 驟埼∫憾諷九′REJECTED縺ｮ蝣ｴ蜷・');
    Log.i('   - SMTP繧ｵ繝ｼ繝舌・隱崎ｨｼ諠・ｱ繧堤｢ｺ隱・);
    Log.i('   - Gmail繧｢繝励Μ繝代せ繝ｯ繝ｼ繝峨′豁｣縺励＞縺狗｢ｺ隱・);
    Log.i('   - 騾∽ｿ｡蜈・Γ繝ｼ繝ｫ繧｢繝峨Ξ繧ｹ縺梧ｭ｣縺励＞縺狗｢ｺ隱・);
    Log.i('\n2. 驟埼∫憾諷九′PENDING縺ｮ縺ｾ縺ｾ螟峨ｏ繧峨↑縺・ｴ蜷・');
    Log.i('   - Firebase Console 竊・Functions 縺ｧ繝ｭ繧ｰ繧堤｢ｺ隱・);
    Log.i('   - Extension險ｭ螳壹ｒ遒ｺ隱・(繝ｪ繝ｼ繧ｸ繝ｧ繝ｳ縲√さ繝ｬ繧ｯ繧ｷ繝ｧ繝ｳ蜷阪↑縺ｩ)');
    Log.e('\n3. 繧ｨ繝ｩ繝ｼ諠・ｱ縺後≠繧句ｴ蜷・');
    Log.e('   - 繧ｨ繝ｩ繝ｼ繝｡繝・そ繝ｼ繧ｸ繧定ｩｳ縺励￥隱ｭ繧薙〒蟇ｾ蠢・);
  } catch (e, stackTrace) {
    Log.e('笶・繧ｨ繝ｩ繝ｼ: $e');
    Log.i('繧ｹ繧ｿ繝・け繝医Ξ繝ｼ繧ｹ: $stackTrace');
  }
}
