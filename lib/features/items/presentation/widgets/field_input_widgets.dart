import 'package:flutter/material.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/core/utils/date_formatter.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/schemas/domain/field_config.dart';
import 'package:void_app/features/schemas/domain/field_type.dart';
import 'package:void_app/features/schemas/domain/schema_field.dart';

class DynamicFieldInput extends StatelessWidget {
  final SchemaField field;
  final FieldValue? value;
  final String? errorText;
  final ValueChanged<FieldValue> onChanged;

  const DynamicFieldInput({
    super.key,
    required this.field,
    required this.value,
    this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FieldType.text:
      case FieldType.url:
      case FieldType.email:
        return _buildTextInput(context);
      case FieldType.longText:
        return _buildLongTextInput(context);
      case FieldType.number:
        return _buildNumberInput(context);
      case FieldType.boolean:
        return _buildBooleanInput(context);
      case FieldType.rating:
        return _buildRatingInput(context);
      case FieldType.date:
        return _buildDateInput(context);
      case FieldType.dateTime:
        return _buildDateTimeInput(context);
      case FieldType.select:
        return _buildSelectInput(context);
      case FieldType.multiSelect:
        return _buildMultiSelectInput(context);
      case FieldType.image:
        return _buildImageInput(context);
    }
  }

  Widget _buildTextInput(BuildContext context) {
    final strVal = value is TextValue
        ? (value as TextValue).value
        : (value is UrlValue
            ? (value as UrlValue).value
            : (value is EmailValue ? (value as EmailValue).value : ''));

    return TextFormField(
      initialValue: strVal,
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        errorText: errorText,
      ),
      onChanged: (val) {
        if (field.type == FieldType.url) {
          onChanged(UrlValue(val));
        } else if (field.type == FieldType.email) {
          onChanged(EmailValue(val));
        } else {
          onChanged(TextValue(val));
        }
      },
    );
  }

  Widget _buildLongTextInput(BuildContext context) {
    final strVal = value is LongTextValue ? (value as LongTextValue).value : '';

    return TextFormField(
      initialValue: strVal,
      maxLines: 4,
      minLines: 2,
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        errorText: errorText,
        alignLabelWithHint: true,
      ),
      onChanged: (val) => onChanged(LongTextValue(val)),
    );
  }

  Widget _buildNumberInput(BuildContext context) {
    final numVal = value is NumberValue ? (value as NumberValue).value : 0.0;
    final config = field.config is NumberFieldConfig
        ? field.config as NumberFieldConfig
        : const NumberFieldConfig();

    return TextFormField(
      initialValue: value != null ? numVal.toString() : '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        hintText: 'e.g. ${config.min ?? 0}',
        errorText: errorText,
      ),
      onChanged: (val) {
        final parsed = double.tryParse(val) ?? 0.0;
        onChanged(NumberValue(parsed));
      },
    );
  }

  Widget _buildBooleanInput(BuildContext context) {
    final boolVal =
        value is BooleanValue ? (value as BooleanValue).value : false;

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        field.label + (field.required ? ' *' : ''),
        style: AppTypography.bodyMedium,
      ),
      value: boolVal,
      onChanged: (val) => onChanged(BooleanValue(val)),
    );
  }

  Widget _buildRatingInput(BuildContext context) {
    final rating = value is RatingValue ? (value as RatingValue).value : 0.0;
    final config = field.config is RatingFieldConfig
        ? field.config as RatingFieldConfig
        : const RatingFieldConfig();

    final maxStars = config.max.toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              field.label + (field.required ? ' *' : ''),
              style: AppTypography.bodyMedium,
            ),
            Text(
              '$rating / ${config.max}',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (int i = 1; i <= (maxStars <= 10 ? maxStars : 5); i++) ...[
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  i <= rating
                      ? Icons.star
                      : (i - 0.5 <= rating
                          ? Icons.star_half
                          : Icons.star_border),
                  color: Colors.amber,
                  size: 24,
                ),
                onPressed: () => onChanged(RatingValue(i.toDouble())),
              ),
              const SizedBox(width: 4),
            ],
            if (rating > 0)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                tooltip: 'Clear rating',
                onPressed: () => onChanged(const RatingValue(0)),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildDateInput(BuildContext context) {
    final dateVal = value is DateValue ? (value as DateValue).value : null;

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: dateVal ?? DateTime.now(),
          firstDate: DateTime(1800),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(DateValue(picked));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label + (field.required ? ' *' : ''),
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          dateVal != null
              ? DateFormatter.formatShortDate(dateVal)
              : 'Select date',
          style: AppTypography.bodyMedium.copyWith(
            color: dateVal != null ? null : AppColors.textMutedDark,
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeInput(BuildContext context) {
    final dtVal =
        value is DateTimeValue ? (value as DateTimeValue).value : null;

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: dtVal ?? DateTime.now(),
          firstDate: DateTime(1800),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null && context.mounted) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(dtVal ?? DateTime.now()),
          );
          if (pickedTime != null) {
            final combined = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            onChanged(DateTimeValue(combined));
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label + (field.required ? ' *' : ''),
          errorText: errorText,
          suffixIcon: const Icon(Icons.access_time, size: 18),
        ),
        child: Text(
          dtVal != null
              ? DateFormatter.formatDateTime(dtVal)
              : 'Select date & time',
          style: AppTypography.bodyMedium.copyWith(
            color: dtVal != null ? null : AppColors.textMutedDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectInput(BuildContext context) {
    final selVal = value is SelectValue ? (value as SelectValue).value : null;
    final config = field.config is SelectFieldConfig
        ? field.config as SelectFieldConfig
        : const SelectFieldConfig();

    return DropdownButtonFormField<String>(
      initialValue:
          (selVal != null && config.options.contains(selVal)) ? selVal : null,
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        errorText: errorText,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('None', style: TextStyle(color: Colors.grey)),
        ),
        ...config.options.map(
          (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
        ),
      ],
      onChanged: (val) => onChanged(SelectValue(val)),
    );
  }

  Widget _buildMultiSelectInput(BuildContext context) {
    final listVal = value is MultiSelectValue
        ? (value as MultiSelectValue).value
        : <String>[];
    final config = field.config is MultiSelectFieldConfig
        ? field.config as MultiSelectFieldConfig
        : const MultiSelectFieldConfig();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label + (field.required ? ' *' : ''),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: config.options.map((opt) {
            final isSelected = listVal.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (selected) {
                final updated = List<String>.from(listVal);
                if (selected) {
                  updated.add(opt);
                } else {
                  updated.remove(opt);
                }
                onChanged(MultiSelectValue(updated));
              },
            );
          }).toList(),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildImageInput(BuildContext context) {
    final imgUrl = value is ImageValue ? (value as ImageValue).value : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: imgUrl,
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            hintText: 'https://example.com/image.jpg',
            errorText: errorText,
            suffixIcon: const Icon(Icons.image_outlined, size: 18),
          ),
          onChanged: (val) => onChanged(ImageValue(val)),
        ),
        if (imgUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imgUrl,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 120,
                width: 120,
                color: Colors.grey.withValues(alpha: 0.2),
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 32),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
