const _cropUnits = ['kg', 'g', 'bag', 'sack', 'tonne', 'crate', 'bunch'];
const _livestockUnits = ['head', 'animal', 'flock', 'herd'];
const _serviceUnits = ['hour', 'day', 'service'];
const _jobUnits = ['hour', 'day', 'job'];
const _supplyUnits = ['piece', 'pack', 'bottle', 'kg', 'bag', 'litre'];
const _equipmentUnits = ['piece', 'item', 'set', 'day'];
const _cooperativeUnits = ['membership', 'group', 'share'];

const listingUnitsByCategory = <String, List<String>>{
  'crops': _cropUnits,
  'produce': _cropUnits,
  'livestock': _livestockUnits,
  'services': _serviceUnits,
  'jobs': _jobUnits,
  'supplies': _supplyUnits,
  'equipment': _equipmentUnits,
  'cooperatives': _cooperativeUnits,
};

List<String> listingUnitsForCategory(String? categoryId) =>
    listingUnitsByCategory[categoryId] ?? const [];
