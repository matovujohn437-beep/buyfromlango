class SmartResponseModel {
  const SmartResponseModel({
    required this.id,
    required this.title,
    required this.content,
  });

  final int id;
  final String title;
  final String content;

  factory SmartResponseModel.fromJson(Map<String, dynamic> json) {
    return SmartResponseModel(
      id: int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }
}
