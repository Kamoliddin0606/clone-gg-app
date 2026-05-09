import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:open_file/open_file.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_content_block.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_media.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/block_type.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/widgets/knowledge_image_widget.dart';

/// Renders a single [KnowledgeContentBlock]. The renderer just
/// dispatches by block type — actual layout lives in the per-type
/// private widgets below so each can carry its own state (YouTube,
/// WebView controllers).
class ContentBlockRenderer extends StatelessWidget {
  final KnowledgeContentBlock block;
  final String currentLanguage;

  const ContentBlockRenderer({
    super.key,
    required this.block,
    required this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return switch (block.blockType) {
      BlockType.paragraph =>
        _ParagraphBlockWidget(block as ParagraphBlock, currentLanguage),
      BlockType.heading =>
        _HeadingBlockWidget(block as HeadingBlock, currentLanguage),
      BlockType.list => _ListBlockWidget(block as ListBlock, currentLanguage),
      BlockType.quote =>
        _QuoteBlockWidget(block as QuoteBlock, currentLanguage),
      BlockType.callout =>
        _CalloutBlockWidget(block as CalloutBlock, currentLanguage),
      BlockType.image =>
        _ImageBlockWidget(block as ImageBlock, currentLanguage),
      BlockType.embed => _EmbedBlockWidget(block as EmbedBlock),
      BlockType.code => _CodeBlockWidget(block as CodeBlock),
      BlockType.table =>
        _TableBlockWidget(block as TableBlock, currentLanguage),
      BlockType.divider => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
      BlockType.file =>
        _FileBlockWidget(block as FileBlock, currentLanguage),
      // Forward-compat: future backend block types render as nothing
      // until the app catches up. No crash, no debug noise.
      BlockType.unknown => const SizedBox.shrink(),
    };
  }
}

// ---------------------------------------------------------------------------
// PARAGRAPH
// ---------------------------------------------------------------------------

class _ParagraphBlockWidget extends StatelessWidget {
  final ParagraphBlock block;
  final String lang;
  const _ParagraphBlockWidget(this.block, this.lang);

  @override
  Widget build(BuildContext context) {
    final markdown = block.markdownFor(lang) ??
        block.markdownFor('en') ??
        block.markdownFor('ru') ??
        block.markdownFor('uz') ??
        '';
    if (markdown.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MarkdownBody(
        data: markdown,
        selectable: true,
        onTapLink: (_, href, _) {
          if (href == null || href.isEmpty) return;
          final uri = Uri.tryParse(href);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HEADING
// ---------------------------------------------------------------------------

class _HeadingBlockWidget extends StatelessWidget {
  final HeadingBlock block;
  final String lang;
  const _HeadingBlockWidget(this.block, this.lang);

  @override
  Widget build(BuildContext context) {
    final text = block.textFor(lang) ??
        block.textFor('en') ??
        block.textFor('ru') ??
        block.textFor('uz') ??
        '';
    if (text.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final style = switch (block.level) {
      1 => theme.textTheme.headlineSmall,
      2 => theme.textTheme.titleLarge,
      3 => theme.textTheme.titleMedium,
      _ => theme.textTheme.titleSmall,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: style?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// LIST
// ---------------------------------------------------------------------------

class _ListBlockWidget extends StatelessWidget {
  final ListBlock block;
  final String lang;
  const _ListBlockWidget(this.block, this.lang);

  @override
  Widget build(BuildContext context) {
    var items = block.itemsFor(lang);
    if (items.isEmpty) {
      for (final fallback in ['en', 'ru', 'uz']) {
        items = block.itemsFor(fallback);
        if (items.isNotEmpty) break;
      }
    }
    if (items.isEmpty) return const SizedBox.shrink();

    final style = block.style;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(_marker(style, i),
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  Expanded(
                    child: MarkdownBody(
                      data: items[i],
                      selectable: true,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _marker(String style, int index) {
    switch (style) {
      case 'ordered':
        return '${index + 1}.';
      case 'check':
        return '☐';
      default:
        return '•';
    }
  }
}

// ---------------------------------------------------------------------------
// QUOTE
// ---------------------------------------------------------------------------

class _QuoteBlockWidget extends StatelessWidget {
  final QuoteBlock block;
  final String lang;
  const _QuoteBlockWidget(this.block, this.lang);

  @override
  Widget build(BuildContext context) {
    final markdown = block.markdownFor(lang) ??
        block.markdownFor('en') ??
        block.markdownFor('ru') ??
        block.markdownFor('uz') ??
        '';
    if (markdown.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final citation = block.citation();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          border: Border(
            left: BorderSide(color: cs.primary, width: 4),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(data: markdown, selectable: true),
            if (citation != null && citation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('— $citation',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CALLOUT
// ---------------------------------------------------------------------------

class _CalloutBlockWidget extends StatelessWidget {
  final CalloutBlock block;
  final String lang;
  const _CalloutBlockWidget(this.block, this.lang);

  @override
  Widget build(BuildContext context) {
    final markdown = block.markdownFor(lang) ??
        block.markdownFor('en') ??
        block.markdownFor('ru') ??
        block.markdownFor('uz') ??
        '';
    if (markdown.isEmpty) return const SizedBox.shrink();

    final variant = block.variant;
    final (bg, fg, icon) = switch (variant) {
      'warn' => (Colors.orange.shade50, Colors.orange.shade900,
          Icons.warning_amber_outlined),
      'danger' => (Colors.red.shade50, Colors.red.shade900,
          Icons.error_outline),
      'success' => (Colors.green.shade50, Colors.green.shade900,
          Icons.check_circle_outline),
      _ => (Colors.blue.shade50, Colors.blue.shade900, Icons.info_outline),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: MarkdownBody(
                data: markdown,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: fg),
                  strong: TextStyle(color: fg, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// IMAGE
// ---------------------------------------------------------------------------

class _ImageBlockWidget extends StatelessWidget {
  final ImageBlock block;
  final String lang;
  const _ImageBlockWidget(this.block, this.lang);

  @override
  Widget build(BuildContext context) {
    final media = block.media;
    if (media == null) return const SizedBox.shrink();
    final caption = block.captionFor(lang) ??
        block.captionFor('en') ??
        block.captionFor('ru') ??
        block.captionFor('uz');

    final aspect = (media.width != null &&
            media.height != null &&
            media.width! > 0 &&
            media.height! > 0)
        ? media.width! / media.height!
        : 16 / 9;

    final fit =
        block.fit == 'cover' ? BoxFit.cover : BoxFit.contain;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                opaque: true,
                pageBuilder: (_, _, _) =>
                    _PhotoViewPage(media: media, heroTag: 'kn-img-${block.id}'),
              ),
            ),
            child: AspectRatio(
              aspectRatio: aspect,
              child: KnowledgeImageWidget(
                media: media,
                size: KnowledgeImageSize.medium,
                fit: fit,
                heroTag: 'kn-img-${block.id}',
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(caption,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _PhotoViewPage extends StatelessWidget {
  final KnowledgeMedia media;
  final String heroTag;
  const _PhotoViewPage({required this.media, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final url = media.bestUrlFor(preferred: 'large') ??
        media.bestUrlFor(preferred: 'medium') ??
        media.bestUrlFor(preferred: 'small');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: url == null
          ? const Center(
              child: Icon(Icons.image_not_supported, color: Colors.white))
          : PhotoView(
              imageProvider: NetworkImage(url),
              heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
              backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// EMBED — youtube + vimeo + generic webview fallback
// ---------------------------------------------------------------------------

class _EmbedBlockWidget extends StatefulWidget {
  final EmbedBlock block;
  const _EmbedBlockWidget(this.block);

  @override
  State<_EmbedBlockWidget> createState() => _EmbedBlockWidgetState();
}

class _EmbedBlockWidgetState extends State<_EmbedBlockWidget> {
  YoutubePlayerController? _yt;
  WebViewController? _web;

  @override
  void initState() {
    super.initState();
    final block = widget.block;
    if (block.provider == 'youtube' && block.embedId.isNotEmpty) {
      _yt = YoutubePlayerController(
        initialVideoId: block.embedId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
    } else if (block.provider == 'vimeo' && block.embedId.isNotEmpty) {
      _web = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(
          Uri.parse('https://player.vimeo.com/video/${block.embedId}'),
        );
    } else if (block.url != null && block.url!.isNotEmpty) {
      _web = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(block.url!));
    }
  }

  @override
  void dispose() {
    _yt?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_yt != null) {
      child = YoutubePlayer(
        controller: _yt!,
        showVideoProgressIndicator: true,
      );
    } else if (_web != null) {
      child = WebViewWidget(controller: _web!);
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(aspectRatio: 16 / 9, child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CODE
// ---------------------------------------------------------------------------

class _CodeBlockWidget extends StatelessWidget {
  final CodeBlock block;
  const _CodeBlockWidget(this.block);

  @override
  Widget build(BuildContext context) {
    if (block.code.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                block.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: block.code));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TABLE
// ---------------------------------------------------------------------------

class _TableBlockWidget extends StatelessWidget {
  final TableBlock block;
  final String lang;
  const _TableBlockWidget(this.block, this.lang);

  @override
  Widget build(BuildContext context) {
    var headers = block.headersFor(lang);
    var rows = block.rowsFor(lang);
    if (headers.isEmpty && rows.isEmpty) {
      for (final fb in ['en', 'ru', 'uz']) {
        headers = block.headersFor(fb);
        rows = block.rowsFor(fb);
        if (headers.isNotEmpty || rows.isNotEmpty) break;
      }
    }
    if (headers.isEmpty && rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: headers
              .map((h) => DataColumn(
                  label: Text(h,
                      style: const TextStyle(fontWeight: FontWeight.w600))))
              .toList(),
          rows: rows
              .map((r) => DataRow(
                    cells: List.generate(
                      headers.isEmpty ? r.length : headers.length,
                      (i) => DataCell(
                        Text(i < r.length ? r[i] : ''),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FILE
// ---------------------------------------------------------------------------

class _FileBlockWidget extends StatelessWidget {
  final FileBlock block;
  final String lang;
  const _FileBlockWidget(this.block, this.lang);

  @override
  Widget build(BuildContext context) {
    final media = block.media;
    final caption = block.captionFor(lang) ??
        block.captionFor('en') ??
        block.filename ??
        media?.storageKey ??
        'File';

    final url = media?.bestUrlFor(preferred: 'large') ??
        media?.bestUrlFor(preferred: 'medium');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            if (url != null) {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                final launched =
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!launched) {
                  // Fallback: try to open via OpenFile (treats the URL
                  // as a path; harmless if it fails).
                  await OpenFile.open(url);
                }
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caption,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (media?.mimeType != null)
                        Text(media!.mimeType!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
