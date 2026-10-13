import 'package:etribunals/presentation/screens/tribunals/ngt/judgements/ngt_judgement_search_screen.dart';
import 'package:etribunals/presentation/screens/home/home_shell.dart';
import 'package:etribunals/presentation/screens/splash/splash_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/cat/cat_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/cat/cat_case_status_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/cat/cat_cause_list_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/cat/cat_orders_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/tdsat/tdsat_screen.dart';
import 'package:etribunals/core/utils/tdsat_client.dart';
import 'package:etribunals/presentation/screens/tribunals/aptel/aptel_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/sat/sat_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/aft/aft_screen.dart';
import 'package:etribunals/core/utils/aft_client.dart';
import 'package:etribunals/presentation/screens/tribunals/ncdrc/ncdrc_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/atfp/atfp_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/cgit/cgit_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/cestat/cestat_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/cestat/cestat_screens.dart';
import 'package:etribunals/core/utils/cestat_client.dart';
import 'package:etribunals/core/utils/itat_client.dart';
import 'package:etribunals/presentation/screens/tribunals/itat/itat_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/itat/itat_screens.dart';
import 'package:etribunals/presentation/screens/tribunals/coming_soon_tribunal_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/drt/drt_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/drt/drt_case_status_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/drt/drt_cause_list_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/drt/drt_orders_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/drt/drt_transfer_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/actsandrules/acts-and-rules.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/circulars-orders-notifications/circulars-orders-notifications.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/displayboard/displayboard.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/judgements/judgement_prior_may2021.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/judgements/judgement_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/nclat_dashboar_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/notices/notice_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/case_tracker/track_case_status_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/causelist/view_cause_list_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/orders/daily_order_prior_may2021.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/orders/registrar_court_prior_may2021.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/case-status/search-nclt-case.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/nclt_public_list_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/display-board/nclt-display-board.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/nclt-dashboard_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/nclt-order-judgement/search-nclt-order-judgement.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/case-tracker/ngt_case_tracker_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/cause-list/view_ngt_cause_list_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/ngt-dashboard_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/rct/rct_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/rct/rct_case_status_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/rct/rct_cause_list_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/rct/rct_display_board_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/case-status/search-upreat-case.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/cause-list/upreat_cause_list_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/upreat-dashboard_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/upreat-order-judgement/search-upreat-order-judgement.dart';
import 'package:flutter/material.dart';
import 'package:etribunals/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const HomeShell());
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/tribunal/nclat':
        return MaterialPageRoute(builder: (_) => NCLATScreen());
      case '/tribunal/nclt':
        return MaterialPageRoute(builder: (_) => NCLTDasboardScreen());  
      case '/tribunal/upreat':
        return MaterialPageRoute(builder: (_) => UPREATDasboardScreen());
      case '/tribunal/ngt':
        return MaterialPageRoute(builder: (_) => NGTDasboardScreen());
      case '/tribunal/rct':
        return MaterialPageRoute(builder: (_) => RCTScreen());
      case '/tribunal/drt':
        return MaterialPageRoute(builder: (_) => DRTScreen());
      case '/tribunal/cat':
        return MaterialPageRoute(builder: (_) => const CATScreen());
      case '/tribunal/itat':
        return MaterialPageRoute(builder: (_) => ITATScreen());
      case '/tribunal/cestat':
        return MaterialPageRoute(builder: (_) => CESTATScreen());
      case '/tribunal/tdsat':
        return MaterialPageRoute(builder: (_) => TDSATScreen());
      case '/tribunal/aptel':
        return MaterialPageRoute(builder: (_) => APTELScreen());
      case '/tribunal/sat':
        return MaterialPageRoute(builder: (_) => SATScreen());
      case '/tribunal/aft':
        return MaterialPageRoute(builder: (_) => AFTScreen());
      case '/tribunal/ncdrc':
        return MaterialPageRoute(builder: (_) => NCDRCScreen());
      case '/tribunal/atfp':
        return MaterialPageRoute(builder: (_) => ATFPScreen());
      case '/tribunal/cgit':
        return MaterialPageRoute(builder: (_) => CGITScreen());
      case '/tribunal/coming-soon':
        final args = (settings.arguments as Map?) ?? const {};
        return MaterialPageRoute(
          builder: (_) => ComingSoonTribunalScreen(
            name: '${args['name'] ?? 'Tribunal'}',
            fullName: '${args['full'] ?? args['subtitle'] ?? ''}',
            officialUrl: '${args['url'] ?? 'https://india.gov.in'}',
          ),
        );
      case '/nclat/track-case-status':
        return MaterialPageRoute(builder: (_) => TrackCaseStatusScreen());
      case '/nclat/view-cause-list':
        return MaterialPageRoute(builder: (_) => ViewCauseListScreen());
      case '/nclat/judgement':
        return MaterialPageRoute(builder: (_) => ViewJudgementOrdersScreen());
      case '/nclat/priorjudement':
        return MaterialPageRoute(builder: (_) => ViewPriorJudgementOrdersScreen());
      case '/nclat/prior-daily-orders':
        return MaterialPageRoute(builder: (_) => ViewPriorDailyOrdersScreen());
      case '/nclat/prior-daily-orders-registrar':
        return MaterialPageRoute(builder: (_) => ViewPriorDailyOrdersRegistrarScreen());    
      case '/nclat/court-notice':
        return MaterialPageRoute(builder: (_) => NoticeScreen());  
      case '/nclat/circulars-orders-notifications':
        return MaterialPageRoute(builder: (_) => CircularOrderNoticeScreen());
      case '/nclat/acts-rules':
        return MaterialPageRoute(builder: (_) => const ActsAndRulesScreen());  
      case '/nclat/display-board':
        return MaterialPageRoute(builder: (_) => const DisplayBoardScreen());
      case '/nclt/view-cause-list':
        return MaterialPageRoute(
          builder: (_) => const NcltPublicListScreen(
            path: '/all-cause-list',
            heading: 'NCLT cause list',
            showTitleFilter: false,
            showBenchFilter: true,
          ),
        );
      case '/nclt/track-case-status':
        return MaterialPageRoute(builder: (_) =>  SearchNCLTCaseStatusScreen());
      case '/nclt/display-board':
        return MaterialPageRoute(builder: (_) => const NCLTDisplayBoardScreen());
      case '/nclt/order-judgement':
        return MaterialPageRoute(builder: (_) => SearchNCLTOrderJudgementScreen());
      case '/nclt/notifications':
        return MaterialPageRoute(
          builder: (_) => const NcltPublicListScreen(
            path: '/notifcationss',
            heading: 'NCLT notifications',
          ),
        );
      case '/nclt/circulars':
        return MaterialPageRoute(
          builder: (_) => const NcltPublicListScreen(
            path: '/circulars',
            heading: 'NCLT circulars',
          ),
        );
      case '/upreat/track-case-status':
        return MaterialPageRoute(builder: (_) =>  SearchUpreatCaseStatusScreen());
      case '/upreat/order-judgement':
        return MaterialPageRoute(builder: (_) => SearchUpreatOrderJudgementScreen());
      case '/upreat/view-cause-list':
        return MaterialPageRoute(builder: (_) =>  ViewUpreatCauseListScreen());
      case '/ngt/track-case-status':
        return MaterialPageRoute(builder: (_) => NgtTrackCaseStatusScreen());
      case '/ngt/view-cause-list':
        return MaterialPageRoute(builder: (_) =>  ViewNgtCauseListScreen());
      case '/ngt/judgements':
        return MaterialPageRoute(builder: (_) => const NgtJudgementSearchScreen());
      case '/rct/track-case-status':
        return MaterialPageRoute(builder: (_) => const RctTrackCaseStatusScreen());
      case '/rct/view-cause-list':
        return MaterialPageRoute(builder: (_) => const RctCauseListScreen());
      case '/rct/judgements':
        return MaterialPageRoute(builder: (_) => const RctCauseListScreen(judgements: true));
      case '/rct/display-board':
        return MaterialPageRoute(builder: (_) => const RctDisplayBoardScreen());
      case '/drt/case-details':
        return MaterialPageRoute(builder: (_) => const DrtCaseStatusScreen());
      case '/drt/cause-list':
        return MaterialPageRoute(builder: (_) => const DrtCauseListScreen());
      case '/drt/orders':
        return MaterialPageRoute(builder: (_) => const DrtOrdersScreen());
      case '/drt/case-transfer':
        return MaterialPageRoute(builder: (_) => const DrtTransferScreen());
      case '/cat/case-status':
        return MaterialPageRoute(builder: (_) => const CatCaseStatusScreen());
      case '/cat/cause-list':
        return MaterialPageRoute(builder: (_) => const CatCauseListScreen());
      case '/cat/daily-orders':
        return MaterialPageRoute(builder: (_) => const CatOrdersScreen());
      case '/cat/final-orders':
        return MaterialPageRoute(builder: (_) => const CatOrdersScreen(oralFinal: true));
      case '/itat/case-status':
        return MaterialPageRoute(builder: (_) => const ItatCaseStatusScreen());
      case '/itat/orders':
        return MaterialPageRoute(builder: (_) => const ItatOrdersScreen());
      case '/itat/notice-board':
        return MaterialPageRoute(
          builder: (_) => ItatListingScreen(
            title: 'ITAT notice board',
            subtitle: 'Judicial notices and cause lists from itat.gov.in',
            officialUrl: 'https://itat.gov.in/judicial/notice_board',
            loader: ItatClient.instance.noticeBoard,
          ),
        );
      case '/itat/special-bench':
        return MaterialPageRoute(
          builder: (_) => ItatListingScreen(
            title: 'Special bench orders',
            subtitle: 'Official special bench orders from itat.gov.in',
            officialUrl: 'https://itat.gov.in/judicial/sborders',
            loader: ItatClient.instance.specialBenchOrders,
          ),
        );
      case '/cestat/case-details':
        return MaterialPageRoute(builder: (_) => const CestatCaseDetailsSearchScreen());
      case '/cestat/cause-list':
        return MaterialPageRoute(
          builder: (_) => CestatDateSearchScreen(
            title: 'CESTAT cause list',
            subtitle: 'cestat.gov.in/viewcauselist  ·  bench and date',
            officialUrl: CestatClient.causeListUrl,
            search: (bench, date) => CestatClient.instance.searchCauseList(benchId: bench, date: date),
          ),
        );
      case '/cestat/proceedings':
        return MaterialPageRoute(
          builder: (_) => CestatDateSearchScreen(
            title: 'CESTAT court proceedings',
            subtitle: 'cestat.gov.in/viewproceeding  ·  bench and date',
            officialUrl: CestatClient.proceedingsUrl,
            search: (bench, date) => CestatClient.instance.searchProceedings(benchId: bench, date: date),
          ),
        );
      case '/cestat/dashboard':
        return MaterialPageRoute(builder: (_) => const CestatDashboardScreen());
      case '/cestat/daily-orders':
        return MaterialPageRoute(builder: (_) => const CestatOrdersSearchScreen(title: 'CESTAT daily orders'));
      case '/cestat/final-orders':
        return MaterialPageRoute(builder: (_) => const CestatOrdersSearchScreen(title: 'CESTAT final orders', finalOrders: true));
      case '/cestat/final-search':
        return MaterialPageRoute(builder: (_) => const CestatOrdersSearchScreen(title: 'CESTAT final order search', finalOrders: true, allBenches: true));
      case '/cestat/display-board':
        return MaterialPageRoute(builder: (_) => const CestatDisplayBoardScreen());
      case '/tdsat/case-status':
        return MaterialPageRoute(builder: (_) => const TdsatCaseStatusScreen());
      case '/tdsat/cause-list':
        return MaterialPageRoute(builder: (_) => const TdsatCauseListScreen());
      case '/tdsat/daily-orders':
        return MaterialPageRoute(
          builder: (_) => const TdsatListingSearchScreen(title: 'TDSAT daily orders', pageUrl: TdsatClient.dailyOrdersUrl),
        );
      case '/tdsat/judgments':
        return MaterialPageRoute(
          builder: (_) => const TdsatListingSearchScreen(title: 'TDSAT judgments', pageUrl: TdsatClient.judgmentsUrl),
        );
      case '/tdsat/proceedings':
        return MaterialPageRoute(
          builder: (_) => const TdsatListingSearchScreen(title: 'TDSAT record of proceedings', pageUrl: TdsatClient.proceedingsUrl),
        );
      case '/aptel/case-status':
        return MaterialPageRoute(builder: (_) => const AptelCaseStatusScreen());
      case '/aptel/cause-list':
        return MaterialPageRoute(builder: (_) => const AptelCauseListScreen());
      case '/aptel/daily-orders':
        return MaterialPageRoute(builder: (_) => const AptelOrdersSearchScreen(title: 'APTEL daily orders'));
      case '/aptel/judgements':
        return MaterialPageRoute(builder: (_) => const AptelOrdersSearchScreen(title: 'APTEL orders / judgements', judgement: true));
      case '/aptel/display-board':
        return MaterialPageRoute(builder: (_) => const AptelDisplayBoardScreen());
      case '/sat/case-status':
        return MaterialPageRoute(builder: (_) => const SatCaseStatusScreen());
      case '/sat/cause-list':
        return MaterialPageRoute(builder: (_) => const SatCauseListScreen());
      case '/sat/orders':
        return MaterialPageRoute(builder: (_) => const SatOrdersSearchScreen());
      case '/aft/case-status':
        return MaterialPageRoute(builder: (_) => const AftCaseStatusScreen());
      case '/aft/cause-list':
        return MaterialPageRoute(builder: (_) => const AftCauseListScreen());
      case '/aft/orders':
        return MaterialPageRoute(
          builder: (_) => const AftDateSearchScreen(
            title: 'AFT daily orders',
            pageUrl: AftClient.ordersUrl,
            searchPath: '/casestatus/daterange/search',
          ),
        );
      case '/aft/judgements':
        return MaterialPageRoute(
          builder: (_) => const AftDateSearchScreen(
            title: 'AFT judgements',
            pageUrl: AftClient.judgementsUrl,
            searchPath: '/judgements/daterange/search',
          ),
        );
      case '/ncdrc/case-status':
        return MaterialPageRoute(builder: (_) => const NcdrcCaseStatusScreen());
      case '/ncdrc/cause-list':
        return MaterialPageRoute(builder: (_) => const NcdrcCauseListScreen());
      case '/ncdrc/orders':
        return MaterialPageRoute(
          builder: (_) => const NcdrcDateSearchScreen(title: 'NCDRC daily orders', ordersOnly: true),
        );
      case '/ncdrc/judgements':
        return MaterialPageRoute(
          builder: (_) => const NcdrcDateSearchScreen(title: 'NCDRC judgements', judgementsOnly: true),
        );
      case '/ncdrc/display-board':
        return MaterialPageRoute(builder: (_) => const NcdrcDisplayBoardScreen());
      case '/atfp/cause-list':
        return MaterialPageRoute(builder: (_) => const AtfpCauseListScreen());
      case '/atfp/orders':
        return MaterialPageRoute(builder: (_) => const AtfpSearchScreen(title: 'ATFP orders'));
      case '/atfp/judgements':
        return MaterialPageRoute(builder: (_) => const AtfpSearchScreen(title: 'ATFP judgements', judgements: true));
      case '/cgit/cause-list':
        return MaterialPageRoute(builder: (_) => const CgitCauseListScreen());
      case '/cgit/awards':
        return MaterialPageRoute(builder: (_) => const CgitAwardsScreen());
      default:
        Fluttertoast.showToast(
          msg: "Page not found: Redirecting to Home",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return MaterialPageRoute(builder: (_) => const HomeShell());
    }
  }
  
}
