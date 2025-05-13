
class Plaque {
  final int id;
  final int treeId;
  final String name;
  final String description;
  final String imageURL;

  const Plaque({
    required this.id,
    required this.treeId,
    required this.name,
    required this.description,
    required this.imageURL,
  });

  factory Plaque.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'treeId': int treeId,
        'name': String name,
        'description': String description,
        'imageURL': String imageURL,
      } =>
        Plaque(
          id: id,
          treeId: treeId,
          name: name,
          description: description,
          imageURL: imageURL,
        ),
      _ => throw FormatException('Failed to parse JSON for Plaque'),
    };
  }

  static final List<Plaque> _mockPlaques = [
    const Plaque(
      id: 5,
      treeId: 1,
      name: "Test",
      description: "Description",
      imageURL: "test.jpg",
    ),
  ];

  static Future<Plaque?> getPlaque(int treeId) async {
    try {
      return _mockPlaques.firstWhere((plaque) => plaque.treeId == treeId);
    } catch (e) {
      // Return null if no plaque exists for this tree
      return null;
    }
  }

  static Future<List<int>> searchPlaquesByName(String query) async {    
    query = query.toLowerCase();
    List<int> treeIds = [];
    
    for (var plaque in _mockPlaques) {
      if (plaque.name.toLowerCase().contains(query)) {
        treeIds.add(plaque.treeId);
      }
    }
    
    return treeIds;
  }
}