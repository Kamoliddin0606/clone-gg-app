import 'dart:convert';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';

/// Validation result
class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final Map<String, dynamic>? sanitizedData;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.sanitizedData,
  });

  ValidationResult.success([this.sanitizedData])
      : isValid = true,
        errors = const [];

  ValidationResult.failure(this.errors)
      : isValid = false,
        sanitizedData = null;
}

/// Validation error
class ValidationError {
  final String field;
  final String message;
  final ValidationErrorType type;
  final dynamic value;

  const ValidationError({
    required this.field,
    required this.message,
    required this.type,
    this.value,
  });

  @override
  String toString() => '$field: $message';
}

/// Validation error types
enum ValidationErrorType {
  required,
  invalidFormat,
  outOfRange,
  duplicate,
  dependency,
  permission,
  dataIntegrity,
}

/// Data validation service for visit steps
class VisitStepValidationService {
  final SalesReqPermissions _permissions;

  VisitStepValidationService(this._permissions);

  /// Validate visit step data
  Future<ValidationResult> validateVisitStepData({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required Map<String, dynamic> data,
    required String dataType,
  }) async {
    final errors = <ValidationError>[];

    // Basic field validations
    errors.addAll(_validateBasicFields(visitId, clientCode, stepCode, stepName, dataType));

    // Data type specific validations
    switch (dataType) {
      case 'photo':
        errors.addAll(_validatePhotoData(data));
        break;
      case 'audit':
        errors.addAll(_validateAuditData(data));
        break;
      case 'order':
        errors.addAll(_validateOrderData(data));
        break;
      case 'form':
        errors.addAll(_validateFormData(data));
        break;
      case 'note':
        errors.addAll(_validateNoteData(data));
        break;
    }

    // Permission-based validations
    errors.addAll(_validatePermissions(stepCode, dataType, data));

    // Data integrity checks
    errors.addAll(await _validateDataIntegrity(visitId, stepCode, data));

    if (errors.isEmpty) {
      final sanitizedData = _sanitizeData(data);
      return ValidationResult.success(sanitizedData);
    } else {
      return ValidationResult.failure(errors);
    }
  }

  /// Validate basic required fields
  List<ValidationError> _validateBasicFields(
    String visitId,
    String clientCode,
    int stepCode,
    String stepName,
    String dataType,
  ) {
    final errors = <ValidationError>[];

    if (visitId.isEmpty) {
      errors.add(ValidationError(
        field: 'visitId',
        message: 'Visit ID cannot be empty',
        type: ValidationErrorType.required,
        value: visitId,
      ));
    }

    if (clientCode.isEmpty) {
      errors.add(ValidationError(
        field: 'clientCode',
        message: 'Client code cannot be empty',
        type: ValidationErrorType.required,
        value: clientCode,
      ));
    }

    if (stepCode < 1 || stepCode > 100) {
      errors.add(ValidationError(
        field: 'stepCode',
        message: 'Step code must be between 1 and 100',
        type: ValidationErrorType.outOfRange,
        value: stepCode,
      ));
    }

    if (stepName.trim().isEmpty) {
      errors.add(ValidationError(
        field: 'stepName',
        message: 'Step name cannot be empty',
        type: ValidationErrorType.required,
        value: stepName,
      ));
    }

    final validDataTypes = ['photo', 'audit', 'order', 'form', 'note'];
    if (!validDataTypes.contains(dataType)) {
      errors.add(ValidationError(
        field: 'dataType',
        message: 'Invalid data type. Must be one of: ${validDataTypes.join(', ')}',
        type: ValidationErrorType.invalidFormat,
        value: dataType,
      ));
    }

    return errors;
  }

  /// Validate photo data
  List<ValidationError> _validatePhotoData(Map<String, dynamic> data) {
    final errors = <ValidationError>[];

    final imagePath = data['image_path'];
    if (imagePath == null || imagePath.toString().isEmpty) {
      errors.add(ValidationError(
        field: 'image_path',
        message: 'Image path is required for photo data',
        type: ValidationErrorType.required,
        value: imagePath,
      ));
    }

    final thumbnailPath = data['thumbnail_path'];
    if (thumbnailPath == null || thumbnailPath.toString().isEmpty) {
      errors.add(ValidationError(
        field: 'thumbnail_path',
        message: 'Thumbnail path is required for photo data',
        type: ValidationErrorType.required,
        value: thumbnailPath,
      ));
    }

    final fileSize = data['file_size'];
    if (fileSize != null) {
      final size = fileSize is int ? fileSize : int.tryParse(fileSize.toString());
      if (size != null && size > 10 * 1024 * 1024) { // 10MB limit
        errors.add(ValidationError(
          field: 'file_size',
          message: 'Image file size cannot exceed 10MB',
          type: ValidationErrorType.outOfRange,
          value: size,
        ));
      }
    }

    return errors;
  }

  /// Validate audit data
  List<ValidationError> _validateAuditData(Map<String, dynamic> data) {
    final errors = <ValidationError>[];

    final items = data['items'];
    if (items == null || (items is List && items.isEmpty)) {
      errors.add(ValidationError(
        field: 'items',
        message: 'Audit must contain at least one item',
        type: ValidationErrorType.required,
        value: items,
      ));
    }

    if (items is List) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item is Map) {
          final productCode = item['product_code'];
          final expected = item['expected'];
          final actual = item['actual'];

          if (productCode == null || productCode.toString().isEmpty) {
            errors.add(ValidationError(
              field: 'items[$i].product_code',
              message: 'Product code is required for audit item',
              type: ValidationErrorType.required,
              value: productCode,
            ));
          }

          if (expected != null) {
            final exp = expected is int ? expected : int.tryParse(expected.toString());
            if (exp == null || exp < 0) {
              errors.add(ValidationError(
                field: 'items[$i].expected',
                message: 'Expected quantity must be a non-negative integer',
                type: ValidationErrorType.invalidFormat,
                value: expected,
              ));
            }
          }

          if (actual != null) {
            final act = actual is int ? actual : int.tryParse(actual.toString());
            if (act == null || act < 0) {
              errors.add(ValidationError(
                field: 'items[$i].actual',
                message: 'Actual quantity must be a non-negative integer',
                type: ValidationErrorType.invalidFormat,
                value: actual,
              ));
            }
          }
        }
      }
    }

    return errors;
  }

  /// Validate order data
  List<ValidationError> _validateOrderData(Map<String, dynamic> data) {
    final errors = <ValidationError>[];

    final orderNumber = data['order_number'];
    if (orderNumber == null || orderNumber.toString().isEmpty) {
      errors.add(ValidationError(
        field: 'order_number',
        message: 'Order number is required',
        type: ValidationErrorType.required,
        value: orderNumber,
      ));
    }

    final items = data['items'];
    if (items == null || (items is List && items.isEmpty)) {
      errors.add(ValidationError(
        field: 'items',
        message: 'Order must contain at least one item',
        type: ValidationErrorType.required,
        value: items,
      ));
    }

    if (items is List) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item is Map) {
          final productCode = item['product_code'];
          final quantity = item['quantity'];
          final price = item['price'];

          if (productCode == null || productCode.toString().isEmpty) {
            errors.add(ValidationError(
              field: 'items[$i].product_code',
              message: 'Product code is required for order item',
              type: ValidationErrorType.required,
              value: productCode,
            ));
          }

          if (quantity != null) {
            final qty = quantity is int ? quantity : int.tryParse(quantity.toString());
            if (qty == null || qty <= 0) {
              errors.add(ValidationError(
                field: 'items[$i].quantity',
                message: 'Quantity must be a positive integer',
                type: ValidationErrorType.invalidFormat,
                value: quantity,
              ));
            }
          }

          if (price != null) {
            final prc = price is double ? price : double.tryParse(price.toString());
            if (prc == null || prc < 0) {
              errors.add(ValidationError(
                field: 'items[$i].price',
                message: 'Price must be a non-negative number',
                type: ValidationErrorType.invalidFormat,
                value: price,
              ));
            }
          }
        }
      }
    }

    return errors;
  }

  /// Validate form data
  List<ValidationError> _validateFormData(Map<String, dynamic> data) {
    final errors = <ValidationError>[];

    final text = data['text'];
    if (text == null || text.toString().trim().isEmpty) {
      errors.add(ValidationError(
        field: 'text',
        message: 'Form text cannot be empty',
        type: ValidationErrorType.required,
        value: text,
      ));
    }

    final maxLength = 1000; // Example limit
    if (text != null && text.toString().length > maxLength) {
      errors.add(ValidationError(
        field: 'text',
        message: 'Form text cannot exceed $maxLength characters',
        type: ValidationErrorType.outOfRange,
        value: text.toString().length,
      ));
    }

    return errors;
  }

  /// Validate note data
  List<ValidationError> _validateNoteData(Map<String, dynamic> data) {
    final errors = <ValidationError>[];

    final text = data['text'];
    if (text == null || text.toString().trim().isEmpty) {
      errors.add(ValidationError(
        field: 'text',
        message: 'Note text cannot be empty',
        type: ValidationErrorType.required,
        value: text,
      ));
    }

    final maxLength = 500; // Example limit
    if (text != null && text.toString().length > maxLength) {
      errors.add(ValidationError(
        field: 'text',
        message: 'Note text cannot exceed $maxLength characters',
        type: ValidationErrorType.outOfRange,
        value: text.toString().length,
      ));
    }

    return errors;
  }

  /// Validate permissions
  List<ValidationError> _validatePermissions(int stepCode, String dataType, Map<String, dynamic> data) {
    final errors = <ValidationError>[];

    // Check if step is allowed based on permissions
    final visitStep = _permissions.visitSteps.firstWhere(
      (step) => step.stepCode == stepCode,
      orElse: () => VisitStep(stepCode: -1, stepName: '', stepRequired: false),
    );

    if (visitStep.stepCode == -1) {
      errors.add(ValidationError(
        field: 'stepCode',
        message: 'Step $stepCode is not permitted for this user',
        type: ValidationErrorType.permission,
        value: stepCode,
      ));
    }

    // Check data type specific permissions
    switch (dataType) {
      case 'photo':
        // Photo permissions are generally allowed, but could check camera permissions
        break;
      case 'audit':
        if (!_permissions.visit) {
          errors.add(ValidationError(
            field: 'dataType',
            message: 'Audit operations are not permitted for this user',
            type: ValidationErrorType.permission,
            value: dataType,
          ));
        }
        break;
      case 'order':
        if (!_permissions.unplannedOrder) {
          errors.add(ValidationError(
            field: 'dataType',
            message: 'Order operations are not permitted for this user',
            type: ValidationErrorType.permission,
            value: dataType,
          ));
        }
        break;
    }

    return errors;
  }

  /// Validate data integrity
  Future<List<ValidationError>> _validateDataIntegrity(String visitId, int stepCode, Map<String, dynamic> data) async {
    final errors = <ValidationError>[];

    // Check for duplicate entries (this would require database access)
    // For now, just check basic data consistency

    final timestamp = data['timestamp'];
    if (timestamp != null) {
      try {
        DateTime.parse(timestamp.toString());
      } catch (e) {
        errors.add(ValidationError(
          field: 'timestamp',
          message: 'Invalid timestamp format',
          type: ValidationErrorType.invalidFormat,
          value: timestamp,
        ));
      }
    }

    // Check JSON serializability
    try {
      jsonEncode(data);
    } catch (e) {
      errors.add(ValidationError(
        field: 'data',
        message: 'Data contains non-serializable values',
        type: ValidationErrorType.dataIntegrity,
        value: e.toString(),
      ));
    }

    return errors;
  }

  /// Sanitize data
  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Trim strings
    sanitized.updateAll((key, value) {
      if (value is String) {
        return value.trim();
      }
      return value;
    });

    // Ensure timestamps
    if (!sanitized.containsKey('timestamp') || sanitized['timestamp'] == null) {
      sanitized['timestamp'] = DateTime.now().toIso8601String();
    }

    // Normalize numeric values
    sanitized.updateAll((key, value) {
      if (key.contains('quantity') || key.contains('amount') || key.contains('count')) {
        if (value is String) {
          return int.tryParse(value) ?? 0;
        }
      }
      if (key.contains('price') || key.contains('total') || key.contains('sum')) {
        if (value is String) {
          return double.tryParse(value) ?? 0.0;
        }
      }
      return value;
    });

    return sanitized;
  }

  /// Validate step sequence
  ValidationResult validateStepSequence({
    required List<VisitStepProgress> stepProgress,
    required bool isStrictSequence,
    required int currentStepIndex,
  }) {
    final errors = <ValidationError>[];

    if (isStrictSequence) {
      // Check if previous required steps are completed
      for (int i = 0; i < currentStepIndex; i++) {
        final step = stepProgress[i];
        if (step.step.stepRequired && step.status != VisitStepStatus.completed) {
          errors.add(ValidationError(
            field: 'step_sequence',
            message: 'Required step "${step.step.stepName}" must be completed before proceeding',
            type: ValidationErrorType.dependency,
            value: step.step.stepCode,
          ));
        }
      }
    }

    // Check for completed required steps
    final incompleteRequired = stepProgress.where(
      (p) => p.step.stepRequired && p.status != VisitStepStatus.completed,
    );

    if (incompleteRequired.isNotEmpty) {
      errors.add(ValidationError(
        field: 'required_steps',
        message: '${incompleteRequired.length} required steps are not completed',
        type: ValidationErrorType.dependency,
        value: incompleteRequired.map((p) => p.step.stepName).toList(),
      ));
    }

    return errors.isEmpty ? ValidationResult.success() : ValidationResult.failure(errors);
  }

  /// Validate visit completion
  ValidationResult validateVisitCompletion(List<VisitStepProgress> stepProgress) {
    final errors = <ValidationError>[];

    final incompleteRequired = stepProgress.where(
      (p) => p.step.stepRequired && p.status != VisitStepStatus.completed,
    ).toList();

    if (incompleteRequired.isNotEmpty) {
      errors.add(ValidationError(
        field: 'visit_completion',
        message: 'All required steps must be completed before finishing visit',
        type: ValidationErrorType.dependency,
        value: incompleteRequired.map((p) => p.step.stepName).toList(),
      ));
    }

    return errors.isEmpty ? ValidationResult.success() : ValidationResult.failure(errors);
  }
}

/// Validation utilities
class ValidationUtils {
  /// Check if string is valid email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if string is valid phone number
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }

  /// Check if value is within range
  static bool isInRange(dynamic value, {dynamic min, dynamic max}) {
    if (value is num && min is num && max is num) {
      return value >= min && value <= max;
    }
    if (value is String && min is int && max is int) {
      return value.length >= min && value.length <= max;
    }
    return true;
  }

  /// Sanitize string input
  static String sanitizeString(String input) {
    return input.trim().replaceAll(RegExp(r'[^\w\s\-\.]'), '');
  }

  /// Validate file path
  static bool isValidFilePath(String path) {
    return path.isNotEmpty && !path.contains('..') && !path.contains('\n');
  }
}