import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/color_scheme.dart';

class SearchInput extends StatelessWidget {
  const SearchInput({
    required this.controller,
    required this.hint,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final Function (String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        onChanged: onChanged,
        controller: controller,
        style: TextStyle(
          color: lightGreyColor,
        ),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,

          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(36),
              borderSide: BorderSide(width: 0)
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(36),
            borderSide: BorderSide(width: 0),
          ),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(36),
              borderSide: BorderSide(width: 0)
          ),
          hintStyle: TextStyle(color: whiteColor),
          prefixIcon: Padding(padding: const EdgeInsets.all(12),
            child: SvgPicture.asset('assets/icons/search.svg',
              width: 24,
              colorFilter: ColorFilter.mode(lightGreyColor,BlendMode.srcIn),
            ),
          ),
          filled : true,
          fillColor: greyColor,

        ),
      ),
    );
  }
}
