import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Official Shellit vector logo widget.
class ShellitLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;

  const ShellitLogo({
    super.key,
    this.size = 32,
    this.borderRadius,
  });

  /// The clean SVG definition of the Shellit brand icon.
  static const String svgRaw = '''
<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
	 viewBox="0 0 512 512" xml:space="preserve">
<path fill="#1C213D" d="M457.9,512H54.1C24.2,512,0,487.8,0,457.9V54.1C0,24.2,24.2,0,54.1,0h403.8C487.8,0,512,24.2,512,54.1v403.8
	C512,487.8,487.8,512,457.9,512z"/>
<g>
	<linearGradient id="SVGID_1_" gradientUnits="userSpaceOnUse" x1="185.6503" y1="359.0494" x2="185.6503" y2="127.5634">
		<stop offset="0" stop-color="#5FB300"/>
		<stop offset="1" stop-color="#8AEB1A"/>
	</linearGradient>
	<path fill="url(#SVGID_1_)" d="M301.4,310.6c0,17.9-3.3,33.5-9.9,46.7c-6.6,13.2-15.9,24.1-27.7,32.8c-11.9,8.6-26,15-42.4,19.2
		c-16.4,4.2-34.3,6.3-53.7,6.3c-17.2,0-33.9-1-50-3c-16.1-2-32-5.4-47.7-10v-61c7.7,2.7,15.7,5.2,24.1,7.5
		c8.4,2.3,16.8,4.4,25.2,6.2c8.4,1.8,16.9,3.1,25.2,4.1c8.4,1,16.5,1.5,24.4,1.5c11.7,0,21.7-1,29.9-3c8.2-2,14.9-4.8,20.1-8.3
		c5.2-3.5,9-7.7,11.3-12.6c2.3-4.9,3.5-10.2,3.5-16.1c0-8-2.3-14.8-6.9-20.2c-4.6-5.4-10.7-10.3-18.2-14.4
		c-7.5-4.2-16.1-7.9-25.7-11.3c-9.6-3.3-19.4-6.9-29.4-10.8c-10-3.8-19.8-8.2-29.4-13.1c-9.6-4.9-18.2-10.9-25.7-18.1
		c-7.5-7.2-13.6-15.8-18.2-25.7c-4.6-10-6.9-22-6.9-36c0-12.9,2.3-25.1,7-36.7c4.7-11.5,12.1-21.6,22.1-30.3
		c10-8.6,22.9-15.5,38.7-20.6c15.7-5.1,34.7-7.7,57-7.7c6.5,0,13.3,0.3,20.5,0.9c7.1,0.6,14.1,1.3,21.1,2.3c6.9,0.9,13.6,2,20.1,3.3
		c6.4,1.3,12.3,2.6,17.7,3.9v56.5c-5.4-2-11.2-3.8-17.6-5.5c-6.4-1.7-12.9-3.1-19.7-4.4c-6.8-1.3-13.6-2.2-20.5-2.9
		c-6.9-0.7-13.4-1-19.6-1c-10.9,0-20.1,0.9-27.6,2.6c-7.5,1.8-13.7,4.2-18.6,7.3c-4.9,3.1-8.4,6.9-10.5,11.4
		c-2.2,4.5-3.3,9.5-3.3,15.1c0,6.9,2.3,12.8,6.9,17.7c4.6,4.9,10.7,9.4,18.3,13.3c7.6,3.9,16.2,7.6,25.9,11
		c9.6,3.4,19.5,7.1,29.6,11c10.1,3.9,20,8.4,29.6,13.4c9.6,5,18.2,11.1,25.9,18.3c7.6,7.2,13.7,15.7,18.3,25.5
		C299.1,285.7,301.4,297.2,301.4,310.6z"/>
	<path fill="#5FB300" d="M291.3,435.9v-49.7h150.8v49.7H291.3z"/>
</g>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    Widget logo = SvgPicture.string(
      svgRaw,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (borderRadius != null && borderRadius! > 0) {
      logo = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: logo,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: logo,
    );
  }
}
