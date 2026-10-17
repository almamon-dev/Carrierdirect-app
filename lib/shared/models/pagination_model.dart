class PaginationModel<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const PaginationModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
  });

  factory PaginationModel.empty() {
    return const PaginationModel(
      items: [],
      page: 1,
      pageSize: 20,
      totalCount: 0,
      hasMore: false,
    );
  }
}
