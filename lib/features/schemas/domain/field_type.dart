enum FieldType {
  text('text', 'Text'),
  longText('long_text', 'Long Text'),
  number('number', 'Number'),
  boolean('boolean', 'Boolean'),
  date('date', 'Date'),
  dateTime('datetime', 'Date & Time'),
  rating('rating', 'Rating'),
  select('select', 'Select'),
  multiSelect('multiselect', 'Multi-Select'),
  url('url', 'URL'),
  email('email', 'Email'),
  image('image', 'Image');

  final String wireName;
  final String displayName;

  const FieldType(this.wireName, this.displayName);

  static FieldType fromString(String raw) {
    return FieldType.values.firstWhere(
      (e) => e.wireName == raw || e.name == raw,
      orElse: () => FieldType.text,
    );
  }
}
