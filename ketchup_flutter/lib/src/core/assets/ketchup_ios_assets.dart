/// iOS `Assets.xcassets`에서 복사한 2x PNG (`assets/ketchup_ios/`).
abstract final class KetchupIosAssets {
  static const String root = 'assets/ketchup_ios';

  static const String bgPattern = '$root/bg_pattern.png';
  static const String imgLogo = '$root/img_logo.png';
  static const String splashLogo = '$root/splash_logo.png';

  static const String btnHdMore = '$root/btn_hd_more.png';
  static const String btnHdWrite = '$root/btn_hd_write.png';
  static const String btnHdPrev = '$root/btn_hd_prev.png';
  static const String btnPageNext = '$root/btn_page_next.png';
  static const String btnPageNextDisa = '$root/btn_page_next_disa.png';
  static const String btnPagePrevDisa = '$root/btn_page_prev_disa.png';

  static const String writeBtnHdInsta = '$root/write_btnHdInsta.png';
  static const String writeImgUpload = '$root/write_img_upload.png';

  /// iOS `img_dafault_0` + n (0~2)
  static String imgDefault(int n) => '$root/img_default_${n.clamp(0, 2)}.png';

  static const String backupGoogleDrive = '$root/backup_imgGoogleDrive.png';
  static const String backupIcloud = '$root/backup_imgIcloud.png';

  static const String popupAlimTit = '$root/popup_img_alim_tit.png';
  static const String popupBtnBg = '$root/popup_img_btn_bg.png';

  static String passwordDigit(int d) => '$root/password_img_pw_${d.clamp(0, 9)}.png';
  static const String passwordDelete = '$root/password_img_pw_dlt.png';
  static const String passwordKeyOff = '$root/password_img_key_off.png';
  static const String passwordKeyOn = '$root/password_img_key_on.png';

  static String developerBubble(int i) => '$root/developer_bulletBubble0$i.png';
  static String developerMem(int i) => '$root/developer_imgMem0$i.png';
  static const String fontGgomaeng = '$root/font_img_ggomaeng.png';
}
