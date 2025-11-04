# Visit Steps Implementation

## Overview
Visit Steps sahifasi agentlar uchun mijozga tashrif buyurganda bajarilishi kerak bo'lgan qadamlar ketma-ketligini boshqarish uchun mo'ljallangan. Bu sahifa strict sequence (qat'iy ketma-ketlik) va non-strict sequence rejimlarini qo'llab-quvvatlaydi.

## Key Features

### 1. Strict Sequence Logic
- **Qat'iy ketma-ketlik**: Agar `strictSequence = true` bo'lsa, oldingi majburiy qadamlar bajarilmasdan keyingi qadamga ruxsat berilmaydi
- **Majburiy qadamlar**: `stepRequired = true` bo'lgan qadamlar majburiy bajarilishi kerak
- **Ixtiyoriy qadamlar**: `stepRequired = false` bo'lgan qadamlar o'tkazib yuborish mumkin

### 2. UI Components

#### VisitStepsPage
Asosiy sahifa widget'i:
```dart
class VisitStepsPage extends StatelessWidget {
  final TradingPointWithPermissions tradingPoint;

  const VisitStepsPage({
    super.key,
    required this.tradingPoint,
  });
}
```

#### VisitStepsBloc
BLoC pattern asosida state management:
- **States**: VisitStepsInitial, VisitStepsLoading, VisitStepsLoaded, VisitStepsError, VisitStepsCompleted
- **Events**: LoadVisitSteps, CompleteStep, SkipStep, FinishVisit

#### _VisitStepCard
Individual qadam kartasi:
- Qadam holatini ko'rsatadi (pending, inProgress, completed, skipped)
- Majburiy/ixtiyoriy qadam belgisi
- Bajarish va o'tkazib yuborish tugmalari
- Strict sequence uchun lock holati

### 3. Data Models

#### VisitStepProgress
```dart
class VisitStepProgress {
  final VisitStep step;
  final VisitStepStatus status;
  final String? notes;
  final String? skipReason;
  final DateTime? completedAt;
}
```

#### VisitStepStatus
```dart
enum VisitStepStatus {
  pending,
  inProgress,
  completed,
  skipped,
}
```

### 4. Permissions Integration
Sahifa `SalesReqPermissions` modelidan foydalanadi:
- `visit`: Tashrifga ruxsat
- `strictSequence`: Qat'iy ketma-ketlik
- `visitSteps`: Qadamlar ro'yxati

### 5. Navigation Flow
1. Agent home sahifasidan mijozni tanlash
2. Visit tugmasini bosish
3. VisitStepsPage ga o'tish
4. Qadamlar ketma-ketligini bajarish
5. Barcha majburiy qadamlar bajarilganda "Tashrifni yakunlash" tugmasi faollashadi
6. Muvaffaqiyatli yakunlanganda orqaga qaytish

## Implementation Details

### Strict Sequence Logic
```dart
int _getCurrentStepIndex(List<VisitStepProgress> progress, bool isStrictSequence) {
  if (!isStrictSequence) {
    return progress.indexWhere((p) => p.status == VisitStepStatus.pending);
  } else {
    for (int i = 0; i < progress.length; i++) {
      if (progress[i].status == VisitStepStatus.pending) {
        bool canAccess = true;
        for (int j = 0; j < i; j++) {
          if (progress[j].step.stepRequired && progress[j].status != VisitStepStatus.completed) {
            canAccess = false;
            break;
          }
        }
        if (canAccess) return i;
      }
    }
    return -1; // All steps completed
  }
}
```

### UI States
- **Loading**: CircularProgressIndicator
- **Error**: Xatolik xabari va qayta urinish tugmasi
- **Loaded**: Qadamlar ro'yxati, progress bar, action buttons
- **Completed**: Muvaffaqiyat xabari va orqaga qaytish

### Error Handling
- Network xatoliklari
- Permissions mavjud emasligi
- Invalid data
- Database errors

## Testing
Testlar `test/visit_steps_page_test.dart` faylida joylashgan:
- UI rendering testi
- Strict sequence logic testi
- Step completion testi
- Visit completion testi

## Future Enhancements
1. **Visit State Persistence**: Chala qoldirilgan tashriflarning holatini saqlash
2. **Offline Support**: Offline rejimda ishlash
3. **Photo Attachments**: Qadamlar uchun rasm qo'shish
4. **GPS Tracking**: Tashrif davomida GPS tracking
5. **Time Tracking**: Har bir qadam uchun vaqt hisobi
6. **Custom Step Types**: Turli xil qadam turlari (text input, photo, signature, etc.)

## Dependencies
- flutter_bloc: State management
- equatable: Value equality
- intl: Localization
- provider: Dependency injection

## File Structure
```
lib/src/features/agent/presentation/pages/
├── visit_steps_page.dart

lib/src/features/agent/data/models/
├── trading_point_with_permissions.dart
├── sales_req_permissions.dart

test/
├── visit_steps_page_test.dart
```

## Usage Example
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => VisitStepsPage(
      tradingPoint: selectedTradingPoint,
    ),
  ),
);
```

Bu implementation zamonaviy Flutter best practices va clean architecture principles ga asosan yaratilgan.