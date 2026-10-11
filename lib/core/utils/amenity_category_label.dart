// ═══════════════════════════════════════════════════════════════════
//  AMENITY CATEGORY — wire value vs. jo user ko dikhta hai
// ═══════════════════════════════════════════════════════════════════
// Amenity ki category backend ke enum se aati hai (models/amenities.js)
// aur POST /amenities usi enum ko validate karta hai — isliye string
// bilkul waisi hi bhejni padti hai. Sirf display badalna ho to yahan
// map karo, wire value ko haath mat lagao.

/// Backend category string → screen par dikhne wala label.
/// Unknown/custom category jaisi hai waisi hi wapas aati hai.
String amenityCategoryLabel(String category) {
  switch (category.trim()) {
    // "Employee" ke saath "Worker" bhi — app me dono shabd saath chalte
    // hain, par backend enum me sirf "Employee Rewards" hi valid hai.
    case 'Employee Rewards':
      return 'Employee / Worker Rewards';
    default:
      return category;
  }
}
