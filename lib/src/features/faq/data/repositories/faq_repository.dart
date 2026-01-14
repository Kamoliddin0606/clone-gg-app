import 'package:flutter/material.dart';
import '../models/faq_section_model.dart';
import '../models/faq_item_model.dart';
import '../../domain/enums/employee_type.dart';

/// Repository providing FAQ content based on employee type.
/// All content is defined here with localization keys.
class FaqRepository {
  /// Returns FAQ sections for the given employee type.
  static List<FaqSection> getSectionsForType(EmployeeType type) {
    switch (type) {
      case EmployeeType.supervisor:
        return _supervisorSections;
      case EmployeeType.salesRep:
        return _salesRepSections;
    }
  }

  /// Supervisor sections - 6 main categories
  static const List<FaqSection> _supervisorSections = [
    // 1. GPS Monitoring
    FaqSection(
      id: 'sv_gps',
      titleKey: 'faqSvGpsTitle',
      icon: Icons.location_on_outlined,
      accentColor: Color(0xFF4CAF50),
      order: 1,
      items: [
        FaqItem(
          id: 'sv_gps_1',
          titleKey: 'faqSvGpsMorningTitle',
          contentKey: 'faqSvGpsMorningContent',
          icon: Icons.wb_sunny_outlined,
          order: 1,
        ),
        FaqItem(
          id: 'sv_gps_2',
          titleKey: 'faqSvGpsEveningTitle',
          contentKey: 'faqSvGpsEveningContent',
          icon: Icons.nights_stay_outlined,
          order: 2,
        ),
      ],
    ),
    // 2. Sales Reports
    FaqSection(
      id: 'sv_sales',
      titleKey: 'faqSvSalesTitle',
      icon: Icons.trending_up_outlined,
      accentColor: Color(0xFF2196F3),
      order: 2,
      items: [
        FaqItem(
          id: 'sv_sales_1',
          titleKey: 'faqSvSalesInterimTitle',
          contentKey: 'faqSvSalesInterimContent',
          icon: Icons.schedule_outlined,
          order: 1,
        ),
        FaqItem(
          id: 'sv_sales_2',
          titleKey: 'faqSvSalesFinalTitle',
          contentKey: 'faqSvSalesFinalContent',
          icon: Icons.assessment_outlined,
          order: 2,
        ),
      ],
    ),
    // 3. KPI & Planning
    FaqSection(
      id: 'sv_kpi',
      titleKey: 'faqSvKpiTitle',
      icon: Icons.flag_outlined,
      accentColor: Color(0xFFFF9800),
      order: 3,
      items: [
        FaqItem(
          id: 'sv_kpi_1',
          titleKey: 'faqSvKpiMondayTitle',
          contentKey: 'faqSvKpiMondayContent',
          icon: Icons.event_outlined,
          order: 1,
        ),
        FaqItem(
          id: 'sv_kpi_2',
          titleKey: 'faqSvKpiAnalysisTitle',
          contentKey: 'faqSvKpiAnalysisContent',
          icon: Icons.analytics_outlined,
          order: 2,
        ),
      ],
    ),
    // 4. Travel Plans
    FaqSection(
      id: 'sv_travel',
      titleKey: 'faqSvTravelTitle',
      icon: Icons.calendar_month_outlined,
      accentColor: Color(0xFF9C27B0),
      order: 4,
      items: [
        FaqItem(
          id: 'sv_travel_1',
          titleKey: 'faqSvTravelMonthlyTitle',
          contentKey: 'faqSvTravelMonthlyContent',
          icon: Icons.route_outlined,
          order: 1,
        ),
      ],
    ),
    // 5. Time Tracking
    FaqSection(
      id: 'sv_time',
      titleKey: 'faqSvTimeTitle',
      icon: Icons.schedule_outlined,
      accentColor: Color(0xFF00BCD4),
      order: 5,
      items: [
        FaqItem(
          id: 'sv_time_1',
          titleKey: 'faqSvTimeWeeklyTitle',
          contentKey: 'faqSvTimeWeeklyContent',
          icon: Icons.date_range_outlined,
          order: 1,
        ),
        FaqItem(
          id: 'sv_time_2',
          titleKey: 'faqSvTimeMonthlyTitle',
          contentKey: 'faqSvTimeMonthlyContent',
          icon: Icons.calendar_today_outlined,
          order: 2,
        ),
      ],
    ),
    // 6. Salary & KPI Reports
    FaqSection(
      id: 'sv_salary',
      titleKey: 'faqSvSalaryTitle',
      icon: Icons.payments_outlined,
      accentColor: Color(0xFF4CAF50),
      order: 6,
      items: [
        FaqItem(
          id: 'sv_salary_1',
          titleKey: 'faqSvSalaryKpiTitle',
          contentKey: 'faqSvSalaryKpiContent',
          icon: Icons.summarize_outlined,
          order: 1,
        ),
        FaqItem(
          id: 'sv_salary_2',
          titleKey: 'faqSvSalaryCalcTitle',
          contentKey: 'faqSvSalaryCalcContent',
          icon: Icons.calculate_outlined,
          order: 2,
        ),
      ],
    ),
  ];

  /// Sales Representative sections - 6 main categories
  static const List<FaqSection> _salesRepSections = [
    // 1. General Provisions
    FaqSection(
      id: 'tp_general',
      titleKey: 'faqTpGeneralTitle',
      icon: Icons.info_outlined,
      accentColor: Color(0xFF607D8B),
      order: 1,
      items: [
        FaqItem(
          id: 'tp_general_1',
          titleKey: 'faqTpGeneralPurposeTitle',
          contentKey: 'faqTpGeneralPurposeContent',
          icon: Icons.description_outlined,
          order: 1,
        ),
      ],
    ),
    // 2. Working Hours & Route
    FaqSection(
      id: 'tp_hours',
      titleKey: 'faqTpHoursTitle',
      icon: Icons.access_time_outlined,
      accentColor: Color(0xFF2196F3),
      order: 2,
      items: [
        FaqItem(
          id: 'tp_hours_1',
          titleKey: 'faqTpHoursScheduleTitle',
          contentKey: 'faqTpHoursScheduleContent',
          icon: Icons.schedule_outlined,
          order: 1,
        ),
        FaqItem(
          id: 'tp_hours_2',
          titleKey: 'faqTpHoursRouteTitle',
          contentKey: 'faqTpHoursRouteContent',
          icon: Icons.route_outlined,
          order: 2,
        ),
        FaqItem(
          id: 'tp_hours_3',
          titleKey: 'faqTpHoursDelayTitle',
          contentKey: 'faqTpHoursDelayContent',
          icon: Icons.warning_amber_outlined,
          order: 3,
        ),
      ],
    ),
    // 3. Trade Point Visits
    FaqSection(
      id: 'tp_visits',
      titleKey: 'faqTpVisitsTitle',
      icon: Icons.store_outlined,
      accentColor: Color(0xFF4CAF50),
      order: 3,
      items: [
        FaqItem(
          id: 'tp_visits_1',
          titleKey: 'faqTpVisitsDailyTitle',
          contentKey: 'faqTpVisitsDailyContent',
          icon: Icons.place_outlined,
          order: 1,
        ),
        FaqItem(
          id: 'tp_visits_2',
          titleKey: 'faqTpVisitsChangesTitle',
          contentKey: 'faqTpVisitsChangesContent',
          icon: Icons.edit_road_outlined,
          order: 2,
        ),
        FaqItem(
          id: 'tp_visits_3',
          titleKey: 'faqTpVisitsPhotoTitle',
          contentKey: 'faqTpVisitsPhotoContent',
          icon: Icons.photo_camera_outlined,
          order: 3,
        ),
      ],
    ),
    // 4. Video Reports (Telegram)
    FaqSection(
      id: 'tp_video',
      titleKey: 'faqTpVideoTitle',
      icon: Icons.videocam_outlined,
      accentColor: Color(0xFF9C27B0),
      order: 4,
      items: [
        FaqItem(
          id: 'tp_video_1',
          titleKey: 'faqTpVideoMorningTitle',
          contentKey: 'faqTpVideoMorningContent',
          icon: Icons.wb_sunny_outlined,
          order: 1,
        ),
        FaqItem(
          id: 'tp_video_2',
          titleKey: 'faqTpVideoDuringTitle',
          contentKey: 'faqTpVideoDuringContent',
          icon: Icons.storefront_outlined,
          order: 2,
        ),
        FaqItem(
          id: 'tp_video_3',
          titleKey: 'faqTpVideoEndTitle',
          contentKey: 'faqTpVideoEndContent',
          icon: Icons.nights_stay_outlined,
          order: 3,
        ),
      ],
    ),
    // 5. Reporting Requirements
    FaqSection(
      id: 'tp_reporting',
      titleKey: 'faqTpReportingTitle',
      icon: Icons.assignment_outlined,
      accentColor: Color(0xFFFF9800),
      order: 5,
      items: [
        FaqItem(
          id: 'tp_reporting_1',
          titleKey: 'faqTpReportingRealTimeTitle',
          contentKey: 'faqTpReportingRealTimeContent',
          icon: Icons.upload_outlined,
          order: 1,
        ),
        FaqItem(
          id: 'tp_reporting_2',
          titleKey: 'faqTpReportingConsequenceTitle',
          contentKey: 'faqTpReportingConsequenceContent',
          icon: Icons.error_outline,
          order: 2,
        ),
      ],
    ),
    // 6. Responsibility
    FaqSection(
      id: 'tp_responsibility',
      titleKey: 'faqTpResponsibilityTitle',
      icon: Icons.gavel_outlined,
      accentColor: Color(0xFFF44336),
      order: 6,
      items: [
        FaqItem(
          id: 'tp_responsibility_1',
          titleKey: 'faqTpResponsibilityRulesTitle',
          contentKey: 'faqTpResponsibilityRulesContent',
          icon: Icons.rule_outlined,
          order: 1,
        ),
        FaqItem(
          id: 'tp_responsibility_2',
          titleKey: 'faqTpResponsibilityMeasuresTitle',
          contentKey: 'faqTpResponsibilityMeasuresContent',
          icon: Icons.warning_outlined,
          order: 2,
        ),
      ],
    ),
  ];
}
