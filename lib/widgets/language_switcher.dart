import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/language_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isHindi = langProvider.isHindi;

    return GestureDetector(
      onTap: () => langProvider.toggleLanguage(),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: AppColors.white.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHindi ? '🇮🇳' : '🇬🇧',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(width: 6.w),
            Text(
              isHindi ? 'हिंदी' : 'English',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.swap_horiz_rounded,
                color: AppColors.white, size: 14.sp),
          ],
        ),
      ),
    );
  }
}