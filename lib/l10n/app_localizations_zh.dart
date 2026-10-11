// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get about => '关于';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get open => '打开';

  @override
  String get share => '分享';

  @override
  String get export => '导出';

  @override
  String get clear => '清除';

  @override
  String get delete => '删除';

  @override
  String get rename => '重命名';

  @override
  String get crop => '裁剪';

  @override
  String get done => '完成';

  @override
  String get next => '下一步';

  @override
  String get skip => '跳过';

  @override
  String get loading => '正在加载';

  @override
  String get home => '首页';

  @override
  String get demo => '使用教程';

  @override
  String get quality => '质量';

  @override
  String get version => '版本';

  @override
  String get select => '选择';

  @override
  String get select_all => '全选';

  @override
  String get select_pages => '选择页面';

  @override
  String get try_again => '重试';

  @override
  String get undo => '撤销';

  @override
  String get not_now => '暂不';

  @override
  String get open_settings => '打开设置';

  @override
  String get more => '更多';

  @override
  String get sort => '排序';

  @override
  String get settings => '设置';

  @override
  String get tutorial => '使用教程';

  @override
  String get library => '文档库';

  @override
  String get scan => '扫描';

  @override
  String get image => '图像';

  @override
  String get images => '图像';

  @override
  String get developers => '开发者';

  @override
  String get view_on_linkedin => '在 LinkedIn 上查看';

  @override
  String get tutorial_title => '如何使用本应用？';

  @override
  String get cant_be_undone => '此操作无法撤销。';

  @override
  String get rotate => '旋转';

  @override
  String get rotate_left => '向左旋转';

  @override
  String get rotate_right => '向右旋转';

  @override
  String pages_count(int count) {
    return '$count 页';
  }

  @override
  String get scan_options => '扫描选项';

  @override
  String get live_scan => '实时扫描';

  @override
  String get import_from_gallery => '从相册导入';

  @override
  String get import_from_gallery_short => '从相册导入';

  @override
  String get refresh => '下拉刷新';

  @override
  String get last_updated => '最近更新';

  @override
  String get sort_order => '排序方式';

  @override
  String get search_documents => '搜索文档';

  @override
  String get no_documents_yet => '暂无文档';

  @override
  String get no_documents_body => '扫描第一页只需约两秒，文档仅保存在此设备上。';

  @override
  String get start_scanning => '开始扫描';

  @override
  String no_results_for(String query) {
    return '未找到“$query”的搜索结果';
  }

  @override
  String get refreshing => '正在刷新…';

  @override
  String get exporting => '正在导出…';

  @override
  String n_selected(int count) {
    return '已选择 $count 项';
  }

  @override
  String get delete_document_q => '删除文档？';

  @override
  String delete_n_documents_q(int count) {
    return '删除 $count 份文档？';
  }

  @override
  String get document_deleted => '文档已删除';

  @override
  String n_documents_deleted(int count) {
    return '已删除 $count 份文档';
  }

  @override
  String saved_n_to_device(int count) {
    return '已将 $count 项保存到设备';
  }

  @override
  String couldnt_export_n(int count) {
    return '有 $count 项无法导出';
  }

  @override
  String date_and_pages(String date, String pages) {
    return '$date · $pages';
  }

  @override
  String get sort_last_modified => '最近修改';

  @override
  String get sort_date_created => '创建日期';

  @override
  String get sort_name => '名称（A–Z）';

  @override
  String get sort_page_count => '页数';

  @override
  String get scanning => '正在扫描';

  @override
  String get auto_capture => '自动拍摄';

  @override
  String get auto_capture_desc => '页面保持稳定时自动拍摄。';

  @override
  String get capture_sound => '拍摄提示音';

  @override
  String get keep_original => '保留原始图像';

  @override
  String get keep_original_desc => '保留未裁剪的照片，以便之后从完整原图重新裁剪页面。文档占用的空间大约会翻倍。';

  @override
  String get avoid_gesture_strip => '避开返回手势区域';

  @override
  String get avoid_gesture_strip_desc =>
      '使裁剪角点远离屏幕边缘，避免拖动时误触系统返回手势。页面显示宽度会略微减小。';

  @override
  String get default_filter => '默认滤镜';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get language => '语言';

  @override
  String get accent_color => '强调色';

  @override
  String get privacy_storage => '隐私与存储';

  @override
  String get privacy_body => 'OpenScan 不会将你的文档发送到任何地方。无需账号，不使用云端服务，也不收集遥测数据。';

  @override
  String get cache => '缓存';

  @override
  String get clear_cache_q => '清除缓存？';

  @override
  String clear_cache_body(String size) {
    return '将释放 $size 的缩略图数据，不会影响你的文档。';
  }

  @override
  String cache_clear_action(String size) {
    return '$size · 清除';
  }

  @override
  String get cache_cleared => '缓存已清除';

  @override
  String get couldnt_clear_cache => '无法清除缓存';

  @override
  String get theme_system => '跟随系统';

  @override
  String get theme_light => '浅色';

  @override
  String get theme_dark => '深色';

  @override
  String get filters => '滤镜';

  @override
  String get filter_original => '原图';

  @override
  String get filter_auto => '自动';

  @override
  String get filter_lighten => '提亮';

  @override
  String get filter_grayscale => '灰度';

  @override
  String get filter_bw => '黑白';

  @override
  String get filter_whiteboard => '白板';

  @override
  String get filter_action => '滤镜';

  @override
  String get apply_to_all_pages => '应用到所有页面';

  @override
  String apply_to_all_n_pages(int count) {
    return '应用到全部 $count 页';
  }

  @override
  String get adjust_edges => '调整边缘';

  @override
  String get automatic_crop => '自动裁剪';

  @override
  String get no_crop => '不裁剪';

  @override
  String get rescan => '重新扫描';

  @override
  String get couldnt_crop => '无法裁剪图像，请重试。';

  @override
  String get looking_for_document => '正在寻找文档…';

  @override
  String get document_detected => '已检测到文档';

  @override
  String get hold_still => '请保持稳定…';

  @override
  String get auto_on => '自动 · 开';

  @override
  String get auto_off => '自动 · 关';

  @override
  String get low_light => '光线不足，请保持稳定或打开闪光灯';

  @override
  String get torch_on => '打开闪光灯';

  @override
  String get torch_off => '关闭闪光灯';

  @override
  String get torch_unavailable => '此设备不支持闪光灯。';

  @override
  String get auto_capture_on => '自动拍摄已开启';

  @override
  String get auto_capture_off => '自动拍摄已关闭';

  @override
  String get undo_last_capture => '撤销上一次拍摄';

  @override
  String get composition_grid => '构图网格';

  @override
  String get switch_camera => '切换摄像头';

  @override
  String get couldnt_capture => '拍摄失败，请重试。';

  @override
  String get couldnt_open_gallery => '无法打开相册。';

  @override
  String get couldnt_start_camera => '无法启动摄像头，请返回后重试。';

  @override
  String get camera_access_needed => '需要摄像头权限';

  @override
  String get camera_access_body =>
      'OpenScan 仅使用摄像头扫描页面，内容不会离开你的设备。请在设置中开启摄像头权限以继续。';

  @override
  String done_count(int count) {
    return '完成 · $count';
  }

  @override
  String get delete_document => '删除文档';

  @override
  String get delete_document_body => '该文档的所有页面也将一并删除，且无法撤销。';

  @override
  String get delete_page_q => '删除页面？';

  @override
  String delete_n_pages_q(int count) {
    return '删除 $count 页？';
  }

  @override
  String get no_pages_title => '此文档暂无页面';

  @override
  String get no_pages_body => '文档会以第一页命名，之后可随时点击标题重命名。';

  @override
  String get continue_scanning => '继续扫描';

  @override
  String get add_pages => '添加页面';

  @override
  String get export_selected => '导出所选内容';

  @override
  String export_n_selected(int count) {
    return '导出选中的 $count 项';
  }

  @override
  String skipped_files(int count) {
    return '已跳过 $count 个本应用无法读取的文件。';
  }

  @override
  String hold_to_reorder(String pages) {
    return '$pages · 长按页面可调整顺序';
  }

  @override
  String export_title(String name) {
    return '导出 · $name';
  }

  @override
  String get quality_caps => '质量';

  @override
  String get page_size => '纸张大小';

  @override
  String get page_size_letter => '美式信纸';

  @override
  String get page_size_legal => '美式法律用纸';

  @override
  String get all_pages => '所有页面';

  @override
  String get selected_pages => '所选页面';

  @override
  String page_x_of_y(int current, int total) {
    return '第 $current 页，共 $total 页';
  }

  @override
  String get exported => '已导出';

  @override
  String get export_failed => '导出失败';

  @override
  String get no_pages_to_export => '没有可导出的页面。';

  @override
  String get pdf_not_written => '无法写入 PDF 文件';

  @override
  String get not_enough_storage => '此设备的存储空间不足。';

  @override
  String get export_went_wrong => '导出时发生错误。';

  @override
  String couldnt_open_file(String message) {
    return '无法打开文件：$message';
  }

  @override
  String get no_app_opens_file => '此手机上没有能够打开该类型文件的应用';

  @override
  String get quality_ultra_low => '极低';

  @override
  String get quality_low => '低';

  @override
  String get quality_medium => '中';

  @override
  String get quality_high => '高';

  @override
  String result_and_more(String name, int count) {
    return '$name，另有 $count 项';
  }

  @override
  String get rename_file => '重命名文件';

  @override
  String get file_name_empty => '文件名不能为空';

  @override
  String get special_chars_not_allowed => '不允许使用特殊字符';

  @override
  String get save_to_device => '保存到设备';

  @override
  String get share_pdf => '分享 PDF';

  @override
  String get share_images => '分享图像';

  @override
  String get demo_scan_title => '将镜头对准页面';

  @override
  String get demo_scan_body => 'OpenScan 会自动识别页面边缘，并在画面稳定时拍摄；你也可以点击快门手动拍摄。';

  @override
  String get demo_pages_title => '继续扫描更多页面';

  @override
  String get demo_pages_body => '每次拍摄的页面都会加入同一文档。全部拍完后，点击“完成”。';

  @override
  String get demo_adjust_title => '校正与优化页面';

  @override
  String get demo_adjust_body => '如果边缘不准确，可拖动角点进行调整，再选择“自动”“灰度”或“黑白”等滤镜。';

  @override
  String get demo_organise_title => '调整顺序并添加页面';

  @override
  String get demo_organise_body => '长按页面可调整顺序，也可以随时向文档添加更多页面。';

  @override
  String get demo_export_title => '保存或分享为 PDF';

  @override
  String get demo_export_body => '选择质量和纸张大小，然后保存到手机或分享出去。';

  @override
  String get demo_privacy_title => '文档始终保留在手机上';

  @override
  String get demo_privacy_body => '无需账号，不使用云端服务，没有广告，也不追踪用户。摄像头仅用于扫描。';

  @override
  String get allow_camera_access => '允许使用摄像头';

  @override
  String get app_description => '是一款开源应用，可扫描纸质文档并将其转换为 PDF 文件。';

  @override
  String get app_description_2 => '无广告。我们不会收集任何数据。\n我们尊重你的隐私。';

  @override
  String get open_source_github => 'GitHub 开源项目';

  @override
  String get couldnt_launch_url => '无法打开链接';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');
}
