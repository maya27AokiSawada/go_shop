class SubscriptionLimits {
  final int maxGroups;
  final int maxMembersPerGroup;

  const SubscriptionLimits({
    required this.maxGroups,
    required this.maxMembersPerGroup,
  });

  static const free = SubscriptionLimits(
    maxGroups: 3,
    maxMembersPerGroup: 10,
  );

  static const premium = SubscriptionLimits(
    maxGroups: 20,
    maxMembersPerGroup: 50,
  );

  static SubscriptionLimits forPremiumStatus(bool isPremium) {
    return isPremium ? premium : free;
  }
}