class NoteModel {
  final String id;
  final String title;
  final String content;
  bool isArchived;
  bool isPinned;
  bool isDeleted;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.isArchived = false,
    this.isPinned = false,
    this.isDeleted = false,
  });
}
