import '../../domain/repositories/photo_repository.dart';
import '../../infra/photo/photo_compressor.dart';
import '../../infra/photo/photo_upload_service.dart';
import '../task_renderer_registry.dart';
import 'audit_form_page.dart';
import 'generic_form_page.dart';
import 'order_create_page.dart';
import 'photo_capture_page.dart';

/// Wires up the built-in renderers and the generic fallback.
///
/// Call once at app start (from `main.dart` or the DI bootstrapper) before
/// any visit screen mounts. Custom task widgets (DEVICE_INVENTORY,
/// PRICETAG_CHECK, …) are added here as they land — every new task is a
/// single `register(...)` line, no existing code touched.
///
/// Two of the built-in renderers (PHOTO_BEFORE / PHOTO_AFTER) need
/// platform-bound singletons (the photo repository, compressor, uploader)
/// so the bootstrap takes them as parameters and curries them into the
/// registered factories.
void registerBuiltInTaskRenderers({
  required PhotoRepository photos,
  required PhotoCompressor compressor,
  required PhotoUploadService uploader,
}) {
  final r = TaskRendererRegistry.instance;
  r.setDefault((ctx) => GenericFormPage(ctx: ctx));

  r.register(
    'PHOTO_BEFORE',
    (ctx) => PhotoCapturePage(
      ctx: ctx,
      photos: photos,
      compressor: compressor,
      uploader: uploader,
      title: 'Foto oldidan',
    ),
  );
  r.register(
    'PHOTO_AFTER',
    (ctx) => PhotoCapturePage(
      ctx: ctx,
      photos: photos,
      compressor: compressor,
      uploader: uploader,
      title: 'Foto keyin',
    ),
  );
  r.register(
    'AUDIT_OWN',
    (ctx) => AuditFormPage(ctx: ctx, title: 'Polka auditi'),
  );
  r.register(
    'AUDIT_COMPETITOR',
    (ctx) => AuditFormPage(
      ctx: ctx,
      title: 'Konkurent auditi',
      codeField: 'brand',
      itemsKey: 'competitors',
    ),
  );
  r.register('ORDER_CREATE', (ctx) => OrderCreatePage(ctx: ctx));
}
