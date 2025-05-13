import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:notepad/constants/color_scheme.dart';
import 'package:notepad/constants/constants.dart';
import 'package:notepad/screen/pages/todos_page.dart';

import 'pages/notes_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;

  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _pageController.animateToPage(0, duration: defaultDuration, curve: Curves.easeInOut),
                      icon: SvgPicture.asset(
                      'assets/icons/notes.svg',
                      width: 28,
                      colorFilter: ColorFilter.mode(
                          _currentPageIndex == 0? primaryColor : greyColor,
                          BlendMode.srcIn,
                        ),
                      ),
                     ),
                      const SizedBox(width: 48),
                  IconButton(onPressed: () => _pageController.animateToPage(1, duration: defaultDuration, curve: Curves.easeInOut),
                  icon :SvgPicture.asset('assets/icons/todos.svg', width: 28,
                    colorFilter: ColorFilter.mode(
                      _currentPageIndex == 1? primaryColor : greyColor,
                      BlendMode.srcIn,
                        ),
                      ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged:(index){
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                children: const [
                  NotesPage(),
                  TodosPage(),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(onPressed: () {},
      child: Icon(Icons.add)
      ),
    );
  }
}
