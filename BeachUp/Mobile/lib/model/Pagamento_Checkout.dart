class PagamentoCheckout {
  final String preferenceId;
  final String initPoint;
  final String sandboxInitPoint;

  PagamentoCheckout({
    required this.preferenceId,
    required this.initPoint,
    required this.sandboxInitPoint,
  });

  factory PagamentoCheckout.fromJson(Map<String, dynamic> json) {
    return PagamentoCheckout(
      preferenceId: json['preferenceId'],
      initPoint: json['initPoint'],
      sandboxInitPoint: json['sandboxInitPoint'],
    );
  }
}