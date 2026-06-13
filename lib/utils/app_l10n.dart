import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// Usage: context.l10n.home  or  AppL10n.of(context).inventory
class AppL10n {
  final String code;
  const AppL10n(this.code);

  static AppL10n of(BuildContext ctx) {
    final code = ctx.watch<LanguageProvider>().locale.languageCode;
    return AppL10n(code);
  }

  String _t(String en, String fr, String ar) {
    if (code == 'fr') return fr;
    if (code == 'ar') return ar;
    return en;
  }

  // ── Navigation ──────────────────────────────────────────────────────────────
  String get home        => _t('Home',      'Accueil',    'الرئيسية');
  String get inventory   => _t('Inventory', 'Inventaire', 'المخزون');
  String get maps        => _t('Maps',      'Cartes',     'الخرائط');
  String get tools       => _t('Tools',     'Outils',     'الأدوات');
  String get profile     => _t('Profile',   'Profil',     'الملف الشخصي');

  // ── Common actions ───────────────────────────────────────────────────────────
  String get save        => _t('Save',      'Enregistrer','حفظ');
  String get cancel      => _t('Cancel',    'Annuler',    'إلغاء');
  String get edit        => _t('Edit',      'Modifier',   'تعديل');
  String get delete      => _t('Delete',    'Supprimer',  'حذف');
  String get add         => _t('Add',       'Ajouter',    'إضافة');
  String get confirm     => _t('Confirm',   'Confirmer',  'تأكيد');
  String get close       => _t('Close',     'Fermer',     'إغلاق');
  String get search      => _t('Search',    'Rechercher', 'بحث');
  String get refresh     => _t('Refresh',   'Actualiser', 'تحديث');
  String get download    => _t('Download',  'Télécharger','تحميل');
  String get select      => _t('Select',    'Sélectionner','اختيار');
  String get back        => _t('Back',      'Retour',     'رجوع');

  // ── Screens ──────────────────────────────────────────────────────────────────
  String get equipmentList    => _t('Equipment List',    'Liste des équipements', 'قائمة المعدات');
  String get addProduct       => _t('Add New Product',   'Ajouter un produit',    'إضافة منتج');
  String get productDetail    => _t('Item Details',      'Détails de l\'article', 'تفاصيل العنصر');
  String get maintenance      => _t('Maintenance',       'Maintenance',           'الصيانة');
  String get notifications    => _t('Notifications',     'Notifications',         'الإشعارات');
  String get analytics        => _t('Analytics',         'Analytique',            'التحليلات');
  String get importProducts   => _t('Import Products',   'Importer des produits', 'استيراد المنتجات');
  String get recentScans      => _t('Recent Scans',      'Scans récents',         'عمليات المسح الأخيرة');
  String get recentActivity   => _t('Recent Activity',   'Activité récente',      'النشاط الأخير');
  String get overview         => _t('Overview',          'Vue d\'ensemble',       'نظرة عامة');
  String get activityFeed     => _t('Activity Feed',     'Fil d\'activité',       'سجل النشاط');
  String get healthScore      => _t('Health Score',      'Score de santé',        'مؤشر الصحة');
  String get warrantyLifecycle=> _t('Warranty & Lifecycle', 'Garantie & Cycle de vie', 'الضمان ودورة الحياة');
  String get maintenanceHistory => _t('Maintenance History', 'Historique de maintenance', 'سجل الصيانة');

  // ── Status labels ─────────────────────────────────────────────────────────────
  String get inStock        => _t('In Stock',       'En stock',        'في المخزن');
  String get operational    => _t('Operational',    'Opérationnel',    'تشغيلي');
  String get inMaintenance  => _t('Maintenance',    'En maintenance',  'قيد الصيانة');
  String get criticalIssue  => _t('Critical Issue', 'Problème critique','مشكلة حرجة');
  String get retired        => _t('Retired',        'Réformé',         'متقاعد');
  String get lost           => _t('Lost',           'Perdu',           'مفقود');

  // ── QR quick actions ──────────────────────────────────────────────────────────
  String get viewDetails    => _t('View Details',     'Voir les détails',  'عرض التفاصيل');
  String get moveItem       => _t('Move Item',        'Déplacer',          'نقل العنصر');
  String get reportIssue    => _t('Report Issue',     'Signaler un problème','الإبلاغ عن مشكلة');
  String get startMaintenance => _t('Start Maintenance', 'Démarrer maintenance', 'بدء الصيانة');
  String get viewHistory    => _t('View History',     'Voir l\'historique', 'عرض السجل');

  // ── Misc ──────────────────────────────────────────────────────────────────────
  String get noData         => _t('No data',         'Aucune donnée',     'لا توجد بيانات');
  String get loading        => _t('Loading…',        'Chargement…',       'جارٍ التحميل…');
  String get error          => _t('Error',           'Erreur',            'خطأ');
  String get language       => _t('Language',        'Langue',            'اللغة');
  String get darkMode       => _t('Dark Mode',       'Mode sombre',       'الوضع الداكن');
  String get settings       => _t('Settings',        'Paramètres',        'الإعدادات');
  String get logout         => _t('Log Out',         'Se déconnecter',    'تسجيل الخروج');
  String get newTask        => _t('New Task',        'Nouvelle tâche',    'مهمة جديدة');
  String get all            => _t('All',             'Tous',              'الكل');
  String get viewAll        => _t('View All',        'Voir tout',         'عرض الكل');
}

extension L10nContext on BuildContext {
  AppL10n get l10n => AppL10n.of(this);
}
