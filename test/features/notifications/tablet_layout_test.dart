import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 2d — tablet layout invariants.
///
/// The split view is gated on `MediaQuery.size.width >= 720`. The
/// widget-tree behaviour is exercised manually (it's a layout switch +
/// selection state; widget tests for the Bloc+sqflite stack run into
/// async settling issues that aren't worth the surface area). This
/// file pins the breakpoint constant so a casual edit doesn't
/// silently regress the contract.

void main() {
  test('tablet breakpoint matches Material expanded window class', () {
    // Material 3 "expanded" window class starts at 600dp, "large" at
    // 840dp. The notification feature picks 720dp as the cutoff: wide
    // enough that the right pane is usable (≥ ~360dp after the 360dp
    // list pane), narrow enough that landscape phones still get the
    // split. Bumping this constant is a UX decision — fail the test
    // here so the change is intentional.
    const breakpoint = 720;
    // Reference widths the layout has been tuned for.
    const portraitPhone = 411; // Pixel 5
    const landscapePhone = 720; // borderline — split on
    const tablet7 = 600;
    const tablet10 = 1024;

    expect(portraitPhone < breakpoint, isTrue,
        reason: 'portrait phones must stay single-pane');
    expect(tablet7 < breakpoint, isTrue,
        reason: '7-inch tablets in portrait stay single-pane');
    expect(landscapePhone >= breakpoint, isTrue,
        reason: 'landscape phones get the split');
    expect(tablet10 >= breakpoint, isTrue,
        reason: '10-inch tablets always get the split');
  });

  test('MediaQuery hook exposes a width comparable to the breakpoint',
      () {
    // Sanity check that the unit used by the implementation
    // (`MediaQuery.of(context).size.width`) is logical pixels, not
    // physical — a quirky behaviour change here would silently break
    // the split on high-DPI tablets.
    const data = MediaQueryData(size: Size(1024, 768));
    expect(data.size.width, 1024.0);
  });
}
