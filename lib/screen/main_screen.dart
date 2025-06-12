import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:notepad/constants/color_scheme.dart';
import 'package:notepad/constants/constants.dart';
import 'package:notepad/screen/pages/todos_page.dart';
import 'package:notepad/screen/pages/notes_page.dart';
import 'package:notepad/screen/pages/archive_page.dart';
import 'package:notepad/screen/pages/trash_page.dart';
import 'package:notepad/screen/pages/settings_page.dart';
import 'package:notepad/screen/pages/label_page.dart';
import 'package:notepad/screen/pages/drawer_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NotesPageState> _notesPageKey = GlobalKey<NotesPageState>();

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

  void _navigateTo(String page) {
    Navigator.pop(context); // Tutup drawer

    if (page == 'catatan') {
      // Kalo yang dipilih "catatan", cukup balikin ke page utama (tanpa push)
      setState(() {
        _currentPageIndex = 0;
      });
      return;
    }

    Widget targetPage;
    switch (page) {
      case 'arsip':
        targetPage = ArchivePage(
          onUnarchive: () {
            Navigator.pop(context); // Balik ke MainScreen
            _pageController.jumpToPage(0); // Pastikan tab NotesPage aktif
            _notesPageKey.currentState?.reloadNotes(); // Panggil reloadNotes di NotesPage!
          },
        );
        break;
      case 'sampah':
        targetPage = TrashPage(
          onNotesRestored: () {
            Navigator.pop(context); // Tutup halaman sampah
            _pageController.jumpToPage(0); // Pastikan tab NotesPage aktif
            _notesPageKey.currentState?.reloadNotes(); // Panggil reloadNotes di NotesPage!
          },
        );
        break;
      case 'setelan':
        targetPage = const SettingsPage();
        break;
      case 'label':
        targetPage = const LabelPage();
        break;
      default:
        targetPage = const NotesPage();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerMenu(onItemSelected: _navigateTo),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  // Tombol drawer (ikon garis tiga)
                  IconButton(
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    icon: const Icon(Icons.menu, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  // Judul halaman dinamis
                  Text(
                    _currentPageIndex == 0 ? 'Catatan' : 'Todos',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _pageController.animateToPage(
                      0,
                      duration: defaultDuration,
                      curve: Curves.easeInOut,
                    ),
                    icon: SvgPicture.asset(
                      'assets/icons/NotePad.svg',
                      width: 28,
                      colorFilter: ColorFilter.mode(
                        _currentPageIndex == 0 ? primaryColor : greyColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: () => _pageController.animateToPage(
                      1,
                      duration: defaultDuration,
                      curve: Curves.easeInOut,
                    ),
                    icon: SvgPicture.asset(
                      'assets/icons/TodoList.svg',
                      width: 28,
                      colorFilter: ColorFilter.mode(
                        _currentPageIndex == 1 ? primaryColor : greyColor,
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
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                children: [
                  NotesPage(key: _notesPageKey),
                  const TodosPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}