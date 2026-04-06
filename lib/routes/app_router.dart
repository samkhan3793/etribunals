import 'package:etribunals/presentation/screens/dashboard_screen.dart';
import 'package:etribunals/presentation/screens/splash/splash_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/drt/drt_screen.dart';
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
import 'package:etribunals/presentation/screens/tribunals/nclt/cause-list/pdf-cause-list.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/display-board/nclt-display-board.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/nclt-circulars/search-nclt-circulars.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/nclt-dashboard_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/nclt-notifications/search-nclt-notifications.dart';
import 'package:etribunals/presentation/screens/tribunals/nclt/nclt-order-judgement/search-nclt-order-judgement.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/case-tracker/ngt_case_tracker_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/cause-list/view_ngt_cause_list_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/ngt-dashboard_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/rct/rct_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/case-status/search-upreat-case.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/cause-list/upreat_cause_list_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/upreat-dashboard_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/upreat-order-judgement/search-upreat-order-judgement.dart';
import 'package:flutter/material.dart';
import 'package:etribunals/auth/login_screen.dart';
import 'package:etribunals/auth/register_screen.dart';
import 'package:etribunals/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => DashboardScreen());
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
        return MaterialPageRoute(builder: (_) =>  NcltCauseListScreen());
      case '/nclt/track-case-status':
        return MaterialPageRoute(builder: (_) =>  SearchNCLTCaseStatusScreen());
      case '/nclt/display-board':
        return MaterialPageRoute(builder: (_) => const NCLTDisplayBoardScreen());
      case '/nclt/order-judgement':
        return MaterialPageRoute(builder: (_) => SearchNCLTOrderJudgementScreen());
      case '/nclt/notifications':
        return MaterialPageRoute(builder: (_) =>  SearchNcltNotificationsScreen());
      case '/nclt/circulars':
        return MaterialPageRoute(builder: (_) => SearchNcltCircularsScreen());
      case '/upreat/track-case-status':
        return MaterialPageRoute(builder: (_) =>  SearchUpreatCaseStatusScreen());
      case '/upreat/display-board':
        return MaterialPageRoute(builder: (_) => const NCLTDisplayBoardScreen());
      case '/upreat/order-judgement':
        return MaterialPageRoute(builder: (_) => SearchUpreatOrderJudgementScreen());
      case '/upreat/notifications':
        return MaterialPageRoute(builder: (_) =>  SearchNcltNotificationsScreen());
      case '/upreat/circulars':
        return MaterialPageRoute(builder: (_) => SearchNcltCircularsScreen());
      case '/upreat/view-cause-list':
        return MaterialPageRoute(builder: (_) =>  ViewUpreatCauseListScreen());
      case '/ngt/notifications':
        return MaterialPageRoute(builder: (_) =>  SearchNcltNotificationsScreen());
      case '/ngt/track-case-status':
        return MaterialPageRoute(builder: (_) => NgtTrackCaseStatusScreen());
      case '/ngt/view-cause-list':
        return MaterialPageRoute(builder: (_) =>  ViewNgtCauseListScreen());
      default:
        Fluttertoast.showToast(
          msg: "Page not found: Redirecting to Onboarding",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
    }
  }
  
}
