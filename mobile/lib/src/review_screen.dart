// Transcript review with plain text, segment and word views.
//
// Confidence and speaker labels come from real engine data. Filters are pure
// helpers in review_filter.dart and are shared by both apps.
library;

import 'package:flutter/material.dart';

import 'kikoe_theme.dart';
import 'l10n.dart';
import 'review_filter.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.title,
    required this.segments,
  });

  final String title;
  final List<ReviewSegment> segments;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> with TickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  String _query = '';
  bool _onlyLow = false;
  int? _speaker;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  String _time(int ms) {
    final seconds = ms ~/ 1000;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String _bandLabel(ConfidenceBand band) {
    switch (band) {
      case ConfidenceBand.high:
        return tr('High');
      case ConfidenceBand.medium:
        return tr('Medium');
      case ConfidenceBand.low:
        return tr('Low');
      case ConfidenceBand.unknown:
        return tr('Unknown');
    }
  }

  Color _bandColor(ConfidenceBand band) {
    switch (band) {
      case ConfidenceBand.high:
        return kOk;
      case ConfidenceBand.medium:
        return kWarning;
      case ConfidenceBand.low:
        return kDanger;
      case ConfidenceBand.unknown:
        return kDim;
    }
  }

  List<ReviewSegment> get _visible => filterReview(
        widget.segments,
        query: _query,
        onlyLow: _onlyLow,
        speaker: _speaker,
      );

  @override
  Widget build(BuildContext context) {
    final speakers = widget.segments
        .map((s) => s.speaker)
        .toSet()
        .where((s) => s > 0)
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabs,
          labelColor: kText,
          unselectedLabelColor: kDim,
          indicatorColor: kBrand,
          tabs: [
            Tab(text: tr('Plain')),
            Tab(text: tr('Segments')),
            Tab(text: tr('Words')),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kSpaceLg, kSpaceLg, kSpaceLg, kSpaceSm),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14, color: kText),
                decoration: InputDecoration(
                  hintText: tr('Search transcript'),
                  hintStyle: const TextStyle(fontSize: 12, color: kDim),
                  prefixIcon: const Icon(Icons.search, size: 18, color: kDim),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    borderSide: const BorderSide(color: kSurface2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpaceLg),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(tr('Only low confidence')),
                    selected: _onlyLow,
                    onSelected: (v) => setState(() => _onlyLow = v),
                  ),
                  const SizedBox(width: kSpaceSm),
                  if (speakers.isNotEmpty)
                    DropdownButton<int?>(
                      value: _speaker,
                      hint: Text(tr('All speakers')),
                      dropdownColor: kSurface,
                      items: [
                        DropdownMenuItem<int?>(value: null, child: Text(tr('All speakers'))),
                        ...speakers.map(
                          (s) => DropdownMenuItem<int?>(
                            value: s,
                            child: Text('${tr('Speaker')} $s'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _speaker = v),
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _PlainView(segments: _visible),
                  _SegmentView(segments: _visible, time: _time, bandLabel: _bandLabel,
                      bandColor: _bandColor),
                  _WordView(segments: _visible, time: _time),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlainView extends StatelessWidget {
  const _PlainView({required this.segments});

  final List<ReviewSegment> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return Center(child: Text(tr('No matches'), style: const TextStyle(color: kDim)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpaceLg),
      child: SelectableText(
        segments.map((s) => s.text).join(' '),
        style: const TextStyle(fontSize: 14, height: 1.5, color: kText),
      ),
    );
  }
}

class _SegmentView extends StatelessWidget {
  const _SegmentView({
    required this.segments,
    required this.time,
    required this.bandLabel,
    required this.bandColor,
  });

  final List<ReviewSegment> segments;
  final String Function(int) time;
  final String Function(ConfidenceBand) bandLabel;
  final Color Function(ConfidenceBand) bandColor;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return Center(child: Text(tr('No matches'), style: const TextStyle(color: kDim)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(kSpaceLg),
      itemCount: segments.length,
      separatorBuilder: (_, _) => const SizedBox(height: kSpaceSm),
      itemBuilder: (context, i) {
        final seg = segments[i];
        final band = confidenceBand(seg.confidence);
        return Container(
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(kRadiusMd),
            border: band == ConfidenceBand.low
                ? const Border(left: BorderSide(color: kDanger, width: 3))
                : null,
          ),
          padding: const EdgeInsets.all(kSpaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${time(seg.startMs)} - ${time(seg.endMs)}',
                      style: const TextStyle(fontSize: 12, color: kDim)),
                  const Spacer(),
                  if (seg.speaker > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: kSpaceSm),
                      child: Chip(
                        label: Text('${tr('Speaker')} ${seg.speaker}',
                            style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  Text(bandLabel(band),
                      style: TextStyle(fontSize: 12, color: bandColor(band))),
                ],
              ),
              const SizedBox(height: kSpaceSm),
              SelectableText(seg.text,
                  style: const TextStyle(fontSize: 14, color: kText, height: 1.5)),
            ],
          ),
        );
      },
    );
  }
}

class _WordView extends StatelessWidget {
  const _WordView({required this.segments, required this.time});

  final List<ReviewSegment> segments;
  final String Function(int) time;

  @override
  Widget build(BuildContext context) {
    final words = segments.expand((s) => s.words).toList();
    if (words.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kSpaceXl),
          child: Text(tr('Word timestamps are off. Enable them for precise timing.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: kDim)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(kSpaceLg),
      itemCount: words.length,
      separatorBuilder: (_, _) => const SizedBox(height: kSpaceXs),
      itemBuilder: (context, i) {
        final word = words[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text('${time(word.startMs)} - ${time(word.endMs)}',
                  style: const TextStyle(fontSize: 12, color: kDim)),
            ),
            Expanded(
              child: SelectableText(word.text,
                  style: const TextStyle(fontSize: 14, color: kText)),
            ),
          ],
        );
      },
    );
  }
}
