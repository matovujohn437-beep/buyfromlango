const _cropItems = [
  'Maize',
  'Beans',
  'Cassava',
  'Rice',
  'Millet',
  'Sorghum',
  'Groundnuts',
  'Sesame',
  'Sweet potatoes',
  'Irish potatoes',
  'Tomatoes',
  'Onions',
  'Cabbage',
  'Sunflower',
  'Coffee',
  'Matooke',
  'Bananas',
  'Avocado',
  'Oranges',
  'Pineapple',
];

const productItemsByCategory = <String, List<String>>{
  'crops': _cropItems,
  'produce': _cropItems,
  'livestock': [
    'Cattle',
    'Goats',
    'Sheep',
    'Pigs',
    'Chicken',
    'Ducks',
    'Turkeys',
    'Eggs',
    'Milk',
    'Beef',
    'Pork',
    'Fish',
  ],
  'services': [
    'Veterinary care',
    'Transport',
    'Ploughing',
    'Irrigation',
    'Farm labour',
    'Produce processing',
    'Soil testing',
    'Pest control',
  ],
  'jobs': [
    'Farm worker',
    'Harvest worker',
    'Tractor operator',
    'Livestock attendant',
    'Agronomist',
    'Delivery driver',
    'Farm manager',
    'Seasonal worker',
  ],
  'supplies': [
    'Animal medicine',
    'Fertilizer',
    'Seeds',
    'Crop protection',
    'Animal feed',
    'Packaging',
  ],
  'equipment': [
    'Hoes',
    'Tractor',
    'Water Pump',
    'Sprayer',
    'Mills',
    'Irrigation equipment',
  ],
  'cooperatives': [
    'Cooperative membership',
    'Farmer group',
  ],
};

List<String> productItemsForCategory(String? categoryId) =>
    productItemsByCategory[categoryId] ?? const [];

String? productCategoryForItem(String? itemName) {
  final normalizedName = itemName?.trim().toLowerCase();
  if (normalizedName == null || normalizedName.isEmpty) return null;
  if (normalizedName == 'tractors' || normalizedName == 'sprayers') {
    return 'equipment';
  }
  for (final entry in productItemsByCategory.entries) {
    if (entry.value.any((item) {
      final normalizedItem = item.toLowerCase();
      return normalizedName == normalizedItem ||
          normalizedName.endsWith(' $normalizedItem');
    })) {
      return entry.key == 'produce' ? 'crops' : entry.key;
    }
  }
  return null;
}
