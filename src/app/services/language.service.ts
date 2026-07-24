import { Injectable, Inject, PLATFORM_ID, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

@Injectable({
  providedIn: 'root'
})
export class LanguageService {
  private isBrowser: boolean;
  public currentLang: any = signal('ar');

  private translations: { [key: string]: { [key: string]: string } } = {
    ar: {
      // General & Navbar
      'store_name': 'فيجن ميديكال للأجهزة الطبية',
      'vision_medical': 'فيجن ميديكال',
      'vision_medical_sub': 'Vision Medical',
      'home': 'الرئيسية',
      'about_us': 'من نحن',
      'contact_us': 'اتصل بنا',
      'admin_dashboard': 'لوحة التحكم',
      'logout': 'تسجيل الخروج',
      'login': 'تسجيل دخول الإدارة',
      'login_title': 'تسجيل دخول الإدارة الآمن',
      'login_sub': 'لوحة تحكم متجر فيجن ميديكال الطبي',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'remember_me': 'تذكرني على هذا الجهاز',
      'login_btn': 'تسجيل الدخول الآمن',
      'back_to_store': 'العودة للمتجر',
      'whatsapp_tooltip': 'تواصل واتساب',
      'currency': 'ج.م',
      'all_rights_reserved': 'جميع الحقوق محفوظة © فيجن ميديكال 2026.',
      'arabic': 'العربية',
      'english': 'English',

      // Home Page
      'hero_title': 'الرعاية الطبية الموثوقة تبدأ من هنا',
      'hero_desc': 'اكتشف مجموعتنا المختارة من الأجهزة الطبية المتطورة والمستلزمات الطبية عالية الكفاءة والمعتمدة محلياً وعالمياً.',
      'search_placeholder': 'ابحث عن جهاز ضغط، كمامات، مستلزمات طبية...',
      'search_btn': 'بحث سريع',
      'active_filters': 'الفلاتر النشطة',
      'clear_all': 'مسح الكل',
      'filter_search': 'بحث',
      'filter_category': 'القسم',
      'filter_brand': 'الماركة',
      'categories_title': 'الأقسام الطبية',
      'all_categories': 'جميع الأقسام',
      'brands_title': 'العلامات التجارية',
      'all_brands': 'جميع الماركات',
      'found_products': 'تم العثور على :count منتج',
      'sorted_by_latest': 'مرتبة حسب الأحدث',
      'no_products_found': 'لا توجد منتجات مطابقة للبحث',
      'no_products_desc': 'يرجى التحقق من الكلمات المستخدمة أو تجربة تصفية الأقسام الأخرى للحصول على منتجات طبية بديلة.',
      'show_all_products': 'عرض جميع المنتجات',
      'in_stock': 'متوفر',
      'out_of_stock': 'غير متوفر',
      'view_details': 'عرض التفاصيل الطبية',
      
      // Product Details Page
      'specifications': 'المواصفات والتفاصيل الطبية',
      'product_overview': 'نظرة عامة على المنتج:',
      'whatsapp_order': 'طلب واستفسار مباشر عبر واتساب',
      'request_info': 'طلب تفاصيل إضافية من الإدارة',
      'whats_prefilled_text': "مرحباً فيجن ميديكال، أرغب في الاستفسار عن وتأكيد طلب المنتج التالي:\n- المنتج: :name\n- السعر: :price ج.م\n- الرابط: :url",
      'whats_general_text': "مرحباً فيجن ميديكال، أرغب في الاستفسار عن الأجهزة والمستلزمات الطبية لديكم.",
      'related_products': 'منتجات ذات صلة قد تهمك',
      'details_label': 'تفاصيل',

      // Reviews & Ratings
      'reviews_title': 'تقييمات العملاء المعتمدة',
      'no_reviews': 'لا توجد تقييمات لهذا المنتج حالياً. كن أول من يشارك رأيه!',
      'add_review': 'أضف تقييمك للمنتج',
      'reviewer_name': 'الاسم بالكامل',
      'reviewer_name_placeholder': 'مثال: د. عبدالله القحطاني',
      'rating_label': 'التقييم (عدد النجوم)',
      'comment_label': 'التعليق والملاحظات',
      'comment_placeholder': 'اكتب تجربتك مع المنتج وملاحظاتك الفنية هنا...',
      'review_moderation_note': 'ملاحظة: تخضع التعليقات والتقييمات للتدقيق والموافقة من قبل الإدارة الطبية للموقع قبل نشرها للعموم.',
      'submit_review': 'إرسال التقييم للمراجعة',
      'review_success': 'شكراً لتقييمك! سيظهر تقييمك في الموقع فور اعتماده من الإدارة.',

      // Contact Us Page
      'contact_title': 'يسعدنا دائماً تواصلك معنا',
      'contact_desc': 'سواء كنت ترغب في الاستفسار عن منتج طبي، أو تبحث عن دعم فني، أو ترغب في التعاون معنا، يرجى اختيار وسيلة التواصل الأنسب لك.',
      'direct_channels': 'قنوات التواصل الفوري',
      'whatsapp_channel': 'واتساب مباشر',
      'call_channel': 'اتصال هاتفي',
      'email_channel': 'البريد الإلكتروني',
      'send_message_title': 'أرسل رسالة للإدارة',
      'name_label': 'الاسم بالكامل',
      'name_placeholder': 'الاسم الثلاثي...',
      'email_placeholder': 'example@mail.com',
      'phone_label': 'رقم الهاتف',
      'phone_placeholder': '01xxxxxxxxx',
      'governorate_label': 'المحافظة',
      'governorate_placeholder': 'اختر المحافظة...',
      'working_hours_label': 'ساعات العمل',
      'opening_time_label': 'وقت الفتح',
      'opening_time_placeholder': '08:00',
      'closing_time_label': 'وقت الإغلاق',
      'closing_time_placeholder': '17:00',
      'address_label': 'العنوان بالتفصيل',
      'address_placeholder': 'المنطقة / الشارع / رقم المبنى...',
      'place_name_label': 'اسم المكان',
      'place_name_placeholder': 'اسم المستشفى / العيادة / المركز الطبي...',
      'subject_label': 'موضوع الرسالة',
      'subject_placeholder': 'مثال: طلب أسعار، صيانة أجهزة...',
      'message_label': 'نص الرسالة',
      'message_placeholder': 'اكتب استفسارك بالتفصيل وسيقوم فريقنا الفني بالرد عليك عبر الهاتف أو البريد الإلكتروني...',
      'submit_message': 'إرسال الرسالة الآن',
      'contact_success': 'تم إرسال رسالتك بنجاح! سنتواصل معك في أقرب وقت.',

      // About Us Page
      'about_title': 'رؤيتنا وقيمنا',
      'about_subtitle': 'فيجن ميديكال رائدة في مجال الأجهزة الطبية وحلول الرعاية الصحية في جمهورية مصر العربية.',
      'about_content_title': 'نبذه عنا',
      'deco_title': 'رعايتكم أولويتنا',
      'deco_desc': 'نضمن لك أن كافة المنتجات المعروضة لدينا حاصلة على تصاريح وزارة الصحة المصرية والجهات المعتمدة للاستخدام الآمن.',
      'highlight_quality': 'جودة معتمدة',
      'highlight_quality_desc': 'منتجاتنا حاصلة على أعلى شهادات الاعتماد والجودة الدولية.',
      'highlight_delivery': 'توصيل سريع',
      'highlight_delivery_desc': 'شحن وتوصيل آمن وبأسرع وقت لجميع المحافظات المصرية.',
      'highlight_support': 'دعم فني متواصل',
      'highlight_support_desc': 'فريقنا جاهز للرد على جميع استفساراتكم الفنية والطبية.',
      'brand_identity': 'الهوية البصرية للعلامة التجارية',
      'brand_identity_subtitle': 'الألوان المعتمدة والدلالات الفنية المستخدمة في شعار فيجن ميديكال للأجهزة الطبية.',
      'color_vision_title': 'فيجين ',
      'color_vision_desc': 'تم استخدام اللون الرمادي التقني (Technical Gray - #6D6E71).',
      'color_medical_title': 'ميدكال',
      'color_medical_desc': 'تم استخدام اللون الفيروزي (Teal - #00A99D).',
      'color_maintenance_title': 'لصيانه الاجهزه الطبيه',
      'color_maintenance_desc': 'تم استخدام اللون الرمادي التقني (Technical Gray - #6D6E71).',

      // Admin Layout & Dashboard
      'admin_portal': 'بوابة الإدارة',
      'admin_dashboard_title': 'لوحة التحكم والإحصائيات الشاملة',
      'admin_home': 'الرئيسية والإحصائيات',
      'admin_categories': 'إدارة الأقسام',
      'admin_brands': 'إدارة الماركات',
      'admin_products': 'إدارة المنتجات',
      'admin_reviews': 'التقييمات والتعليقات',
      'admin_messages': 'رسائل العملاء',
      'admin_settings': 'إعدادات المتجر',
      'admin_role': 'مسؤول النظام',
      'view_store': 'عرض المتجر',
      'total_visitors': 'إجمالي الزوار',
      'today_visitors': 'زوار اليوم: :count',
      'total_products': 'إجمالي المنتجات',
      'displayed_in_catalog': 'معروضة في الكتالوج',
      'categories_and_brands': 'الأقسام والماركات',
      'categories_slash_brands': 'فئات / مصنعين',
      'pending_actions': 'معلق بانتظار الإجراء',
      'reviews_count': 'تقييمات: :count',
      'messages_count': 'رسائل: :count',
      'visitors_stats': 'إحصائيات الزوار (آخر 7 أيام)',
      'live_update': 'تحديث فوري',
      'activity_log': 'سجل النشاطات والمتابعة',
      'no_activities': 'لا توجد عمليات مسجلة بعد.',
      'by_user': 'بواسطة: :name',
      'new_pending_reviews': 'تقييمات جديدة معلقة',
      'view_all': 'عرض الكل',
      'no_pending_reviews': 'لا توجد تقييمات معلقة بانتظار الاعتماد.',
      'on_product': 'على منتج: :name',
      'approve_and_publish': 'موافقة ونشر',
      'delete': 'حذف',
      'unread_messages': 'رسائل تواصل غير مقروءة',
      'no_unread_messages': 'لا توجد رسائل جديدة غير مقروءة.',
      'no_subject': 'بلا عنوان',
      'read_message': 'قراءة الرسالة',
      'chart_label': 'عدد زوار الموقع',
      'pending_reviews_alert': 'تقييمات معلقة بانتظار المراجعة: :count',
      'unread_messages_alert': 'رسائل جديدة غير مقروءة: :count',
      'login_panel_title': 'تسجيل دخول الإدارة',

      // Our Services Section
      'services_title': 'خدماتنا المتميزة',
      'services_subtitle': 'في فيجن ميديكال، نقدم حلولاً طبية متكاملة تضمن سلامة ورعاية عملائنا من خلال معايير فنية عالية.',
      'service_devices_title': 'توفير أجهزة معتمدة',
      'service_devices_desc': 'تأمين أحدث الأجهزة الطبية المرخصة والمطابقة للمعايير المصرية والعالمية.',
      'service_maintenance_title': 'الصيانة والمعايرة',
      'service_maintenance_desc': 'فريق صيانة هندسي متخصص لمعايرة الأجهزة لضمان الدقة والأداء الطبي المستمر.',
      'service_shipping_title': 'شحن وتوصيل سريع',
      'service_shipping_desc': 'شحن وتوصيل آمن للمستلزمات والأجهزة للعيادات والمنازل في أسرع وقت.',
      'service_support_title': 'استشارات ودعم متواصل',
      'service_support_desc': 'تواصل ودعم فني على مدار الساعة للإجابة عن أسئلتكم ومتابعة طلباتكم.',

      // Alerts & Flash Messages
      'settings_updated': 'تم تحديث الإعدادات بنجاح.',
      'review_approved': 'تم اعتماد التقييم بنجاح ونشره في الموقع.',
      'review_deleted': 'تم حذف التقييم بنجاح.',
      'product_created': 'تم إضافة المنتج بنجاح.',
      'product_updated': 'تم تحديث المنتج بنجاح.',
      'product_deleted': 'تم حذف المنتج بنجاح.',
      'message_deleted': 'تم حذف رسالة التواصل بنجاح.',
      'category_created': 'تم إضافة القسم بنجاح.',
      'category_updated': 'تم تحديث القسم بنجاح.',
      'category_deleted': 'تم حذف القسم بنجاح.',
      'brand_created': 'تم إضافة الماركة بنجاح.',
      'brand_updated': 'تم تحديث الماركة بنجاح.',
      'brand_deleted': 'تم حذف الماركة بنجاح.',
      'auth_failed': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',

      // Company Map
      'company_map': 'موقع الشركة على الخريطة',
      'view_on_map': 'افتح موقعنا في خرائط جوجل',
      'map_description': 'تفضل بزيارة مقرنا الرئيسي أو تواصل معنا مباشرة لتسهيل استلام طلباتك.',

      // Maintenance & Restructuring Additionals
      'store': 'المتجر',
      'store_preview_title': 'متجر المستلزمات وقطع الغيار',
      'store_preview_subtitle': 'تصفح تشكيلتنا المتنوعة من المستلزمات الطبية الاستهلاكية وقطع الغيار الأصلية المعتمدة.',
      'browse_store': 'تصفح المتجر الطبي',
      'maintenance_request': 'طلب صيانة أجهزة طبية',
      'maintenance_request_desc': 'أدخل تفاصيل الجهاز والمشكلة الفنية، وسيقوم مهندسونا المختصون بالتواصل معك فوراً.',
      'device_name': 'اسم الجهاز الطبي',
      'device_name_placeholder': 'مثال: جهاز قياس ضغط، جهاز نيبولايزر...',
      'device_model': 'الموديل أو الرقم التسلسلي (إن وجد)',
      'device_model_placeholder': 'مثال: Omron M3, Serial: 123456...',
      'problem_desc': 'وصف الخلل الفني أو العطل بالتفصيل',
      'problem_desc_placeholder': 'يرجى توضيح المشكلة التي تواجهها مع الجهاز...',
      'request_maintenance_btn': 'إرسال طلب الصيانة والاصلاح',
      'maintenance_phone': 'رقم صيانة الأجهزة',
      'maintenance_whatsapp': 'واتساب الصيانة المباشر',
    },
    en: {
      // General & Navbar
      'store_name': 'Vision Medical for Devices',
      'vision_medical': 'Vision Medical',
      'vision_medical_sub': 'Vision Medical',
      'home': 'Home',
      'about_us': 'About Us',
      'contact_us': 'Contact Us',
      'admin_dashboard': 'Dashboard',
      'logout': 'Logout',
      'login': 'Admin Login',
      'login_title': 'Secure Admin Login',
      'login_sub': 'Vision Medical Store Control Panel',
      'email': 'Email Address',
      'password': 'Password',
      'remember_me': 'Remember me on this device',
      'login_btn': 'Secure Login',
      'back_to_store': 'Back to Store',
      'whatsapp_tooltip': 'WhatsApp Chat',
      'currency': 'EGP',
      'all_rights_reserved': 'All rights reserved © Vision Medical 2026.',
      'arabic': 'العربية',
      'english': 'English',

      // Home Page
      'hero_title': 'Trusted Medical Care Starts Here',
      'hero_desc': 'Discover our selected range of advanced medical equipment and high-efficiency medical supplies certified locally and globally.',
      'search_placeholder': 'Search for blood pressure monitors, masks, medical supplies...',
      'search_btn': 'Quick Search',
      'active_filters': 'Active Filters',
      'clear_all': 'Clear All',
      'filter_search': 'Search',
      'filter_category': 'Category',
      'filter_brand': 'Brand',
      'categories_title': 'Medical Categories',
      'all_categories': 'All Categories',
      'brands_title': 'Brands',
      'all_brands': 'All Brands',
      'found_products': 'Found :count products',
      'sorted_by_latest': 'Sorted by latest',
      'no_products_found': 'No products match your search',
      'no_products_desc': 'Please check the words used or try filtering other categories for alternative medical products.',
      'show_all_products': 'Show All Products',
      'in_stock': 'In Stock',
      'out_of_stock': 'Out of Stock',
      'view_details': 'View Medical Details',
      
      // Product Details Page
      'specifications': 'Specifications & Medical Details',
      'product_overview': 'Product Overview:',
      'whatsapp_order': 'Direct Order & Inquiry via WhatsApp',
      'request_info': 'Request Additional Details',
      'whats_prefilled_text': "Hello Vision Medical, I would like to inquire about and confirm ordering the following product:\n- Product: :name\n- Price: :price EGP\n- Link: :url",
      'whats_general_text': "Hello Vision Medical, I would like to inquire about the medical equipment and supplies you have.",
      'related_products': 'Related Products You Might Like',
      'details_label': 'Details',

      // Reviews & Ratings
      'reviews_title': 'Approved Customer Reviews',
      'no_reviews': 'No reviews for this product yet. Be the first to share your opinion!',
      'add_review': 'Add Your Review for the Product',
      'reviewer_name': 'Full Name',
      'reviewer_name_placeholder': 'Example: Dr. John Doe',
      'rating_label': 'Rating (Number of Stars)',
      'comment_label': 'Comment & Feedback',
      'comment_placeholder': 'Write your experience with the product and technical notes here...',
      'review_moderation_note': 'Note: Comments and reviews are subject to verification and approval by the site medical administration before they are published to the public.',
      'submit_review': 'Submit Review for Approval',
      'review_success': 'Thank you for your rating! Your review will appear on the site once it is approved by the administration.',

      // Contact Us Page
      'contact_title': 'We are always happy to connect with you',
      'contact_desc': 'Whether you want to inquire about a medical product, look for technical support, or want to cooperate with us, please choose the most appropriate method for you.',
      'direct_channels': 'Instant Contact Channels',
      'whatsapp_channel': 'Direct WhatsApp',
      'call_channel': 'Phone Call',
      'email_channel': 'Email Address',
      'send_message_title': 'Send Message to Admin',
      'name_label': 'Full Name',
      'name_placeholder': 'Enter your full name...',
      'email_placeholder': 'example@mail.com',
      'phone_label': 'Phone Number',
      'phone_placeholder': '+20 1xxxxxxxxx',
      'governorate_label': 'Governorate',
      'governorate_placeholder': 'Select governorate...',
      'working_hours_label': 'Working Hours',
      'opening_time_label': 'Opening Time',
      'opening_time_placeholder': '08:00',
      'closing_time_label': 'Closing Time',
      'closing_time_placeholder': '17:00',
      'address_label': 'Address Description',
      'address_placeholder': 'District / Street / Building No...',
      'place_name_label': 'Place Name',
      'place_name_placeholder': 'Hospital / Clinic / Medical Center name...',
      'subject_label': 'Message Subject',
      'subject_placeholder': 'Example: Price Request, Equipment Maintenance...',
      'message_label': 'Message Body',
      'message_placeholder': 'Write your inquiry in detail, and our technical team will reply to you via phone or email...',
      'submit_message': 'Send Message Now',
      'contact_success': 'Your message has been sent successfully! We will contact you as soon as possible.',

      // About Us Page
      'about_title': 'Our Vision & Values',
      'about_subtitle': 'Vision Medical is a leader in medical devices and healthcare solutions in Egypt.',
      'about_content_title': 'Who We Are & What We Provide',
      'deco_title': 'Your Care is Our Priority',
      'deco_desc': 'We guarantee that all products displayed by us are licensed by the Egyptian Ministry of Health and approved for safe use.',
      'highlight_quality': 'Certified Quality',
      'highlight_quality_desc': 'Our products have the highest international accreditation and quality certificates.',
      'highlight_delivery': 'Fast Delivery',
      'highlight_delivery_desc': 'Safe shipping and delivery as fast as possible to all Egyptian governorates.',
      'highlight_support': 'Continuous Support',
      'highlight_support_desc': 'Our team is ready to answer all your technical and medical inquiries.',
      'brand_identity': 'Brand Identity & Colors',
      'brand_identity_subtitle': 'The approved colors and technical details used in the Vision Medical official brand logo.',
      'color_vision_title': 'VISION',
      'color_vision_desc': 'Technical Gray color (#6D6E71) was used.',
      'color_medical_title': 'MEDICAL',
      'color_medical_desc': 'Teal color (#00A99D) was used.',
      'color_maintenance_title': 'For Medical Maintenance',
      'color_maintenance_desc': 'Technical Gray color (#6D6E71) was used.',

      // Admin Layout & Dashboard
      'admin_portal': 'Admin Portal',
      'admin_dashboard_title': 'Dashboard & Statistics Overview',
      'admin_home': 'Home & Statistics',
      'admin_categories': 'Categories',
      'admin_brands': 'Brands',
      'admin_products': 'Products',
      'admin_reviews': 'Reviews & Comments',
      'admin_messages': 'Customer Messages',
      'admin_settings': 'Store Settings',
      'admin_role': 'System Admin',
      'view_store': 'View Store',
      'total_visitors': 'Total Visitors',
      'today_visitors': 'Today\'s Visitors: :count',
      'total_products': 'Total Products',
      'displayed_in_catalog': 'Displayed in Catalog',
      'categories_and_brands': 'Categories & Brands',
      'categories_slash_brands': 'Categories / Brands',
      'pending_actions': 'Pending Actions',
      'reviews_count': 'Reviews: :count',
      'messages_count': 'Messages: :count',
      'visitors_stats': 'Visitor Statistics (Last 7 Days)',
      'live_update': 'Live Update',
      'activity_log': 'Activity Log & Tracking',
      'no_activities': 'No activities recorded yet.',
      'by_user': 'By: :name',
      'new_pending_reviews': 'New Pending Reviews',
      'view_all': 'View All',
      'no_pending_reviews': 'No pending reviews awaiting approval.',
      'on_product': 'On product: :name',
      'approve_and_publish': 'Approve & Publish',
      'delete': 'Delete',
      'unread_messages': 'Unread Contact Messages',
      'no_unread_messages': 'No new unread messages.',
      'no_subject': 'No Subject',
      'read_message': 'Read Message',
      'chart_label': 'Number of Site Visitors',
      'pending_reviews_alert': 'Pending reviews awaiting approval: :count',
      'unread_messages_alert': 'New unread messages: :count',
      'login_panel_title': 'Admin Login Panel',

      // Our Services Section
      'services_title': 'Our Premium Services',
      'services_subtitle': 'At Vision Medical, we provide integrated medical solutions that ensure the safety and care of our clients through high technical standards.',
      'service_devices_title': 'Certified Medical Devices',
      'service_devices_desc': 'Securing the latest medical equipment licensed and complying with Egyptian and international standards.',
      'service_maintenance_title': 'Maintenance & Calibration',
      'service_maintenance_desc': 'Specialized engineering team to calibrate devices ensuring accuracy and continuous performance.',
      'service_shipping_title': 'Fast & Secure Delivery',
      'service_shipping_desc': 'Safe shipping and express delivery of medical supplies and devices to clinics and homes.',
      'service_support_title': 'Continuous Consultations',
      'service_support_desc': 'Ongoing support and assistance around the clock to answer your queries and track orders.',

      // Alerts & Flash Messages
      'settings_updated': 'Settings updated successfully.',
      'review_approved': 'Review approved and published successfully.',
      'review_deleted': 'Review deleted successfully.',
      'product_created': 'Product added successfully.',
      'product_updated': 'Product updated successfully.',
      'product_deleted': 'Product deleted successfully.',
      'message_deleted': 'Contact message deleted successfully.',
      'category_created': 'Category added successfully.',
      'category_updated': 'Category updated successfully.',
      'category_deleted': 'Category deleted successfully.',
      'brand_created': 'Brand added successfully.',
      'brand_updated': 'Brand updated successfully.',
      'brand_deleted': 'Brand deleted successfully.',
      'auth_failed': 'Invalid email address or password.',

      // Company Map
      'company_map': 'Company Location Map',
      'view_on_map': 'Open our location in Google Maps',
      'map_description': 'Visit our main office or contact us directly to coordinate your orders easily.',

      // Maintenance & Restructuring Additionals
      'store': 'Store',
      'store_preview_title': 'Supplies & Spare Parts Store',
      'store_preview_subtitle': 'Browse our diverse range of disposable medical supplies and certified genuine spare parts.',
      'browse_store': 'Browse Medical Store',
      'maintenance_request': 'Request Medical Maintenance',
      'maintenance_request_desc': 'Enter device details and the technical issue, and our specialized engineers will contact you immediately.',
      'device_name': 'Medical Device Name',
      'device_name_placeholder': 'e.g., Blood Pressure Monitor, Nebulizer...',
      'device_model': 'Model or Serial Number (if available)',
      'device_model_placeholder': 'e.g., Omron M3, Serial: 123456...',
      'problem_desc': 'Detailed Technical Issue/Defect Description',
      'problem_desc_placeholder': 'Please explain the issue you are facing with the device...',
      'request_maintenance_btn': 'Submit Maintenance Request',
      'maintenance_phone': 'Maintenance Contact No.',
      'maintenance_whatsapp': 'Direct Maintenance WhatsApp',
    }
  };

  constructor(@Inject(PLATFORM_ID) platformId: object) {
    this.isBrowser = isPlatformBrowser(platformId);
    if (this.isBrowser) {
      const savedLang = localStorage.getItem('lang') as 'ar' | 'en';
      if (savedLang === 'ar' || savedLang === 'en') {
        this.currentLang.set(savedLang);
      }
      this.applyLanguage(this.currentLang());
    }
  }

  public setLanguage(lang: 'ar' | 'en') {
    this.currentLang.set(lang);
    if (this.isBrowser) {
      localStorage.setItem('lang', lang);
    }
    this.applyLanguage(lang);
  }

  private applyLanguage(lang: 'ar' | 'en') {
    if (!this.isBrowser) return;
    const dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.setAttribute('lang', lang);
    document.documentElement.setAttribute('dir', dir);
  }

  public translate(key: string, replacements?: { [key: string]: string | number }): string {
    const dict = this.translations[this.currentLang()];
    let text = dict[key] || key;
    if (replacements) {
      Object.keys(replacements).forEach(rKey => {
        text = text.replace(`:${rKey}`, String(replacements[rKey]));
      });
    }
    return text;
  }

  public t(key: string, replacements?: { [key: string]: string | number }): string {
    return this.translate(key, replacements);
  }
}
