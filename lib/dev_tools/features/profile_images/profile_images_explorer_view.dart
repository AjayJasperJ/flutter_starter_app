import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/dimensions.dart';
import '../../../widgets/app_profile_image.dart';
import 'package:path_provider/path_provider.dart';
import '../../widgets/jump_to_bottom_fab.dart';
import '../auth_tools/devtools_auth_controller.dart';

class ProfileImagesExplorerView extends StatefulWidget {
  const ProfileImagesExplorerView({super.key});

  @override
  State<ProfileImagesExplorerView> createState() =>
      _ProfileImagesExplorerViewState();
}

class _ProfileImagesExplorerViewState extends State<ProfileImagesExplorerView> {
  final _cacheManager = ProfileImageCacheManager();
  final ValueNotifier<List<File>> _cachedFiles = ValueNotifier<List<File>>([]);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(true);
  final ValueNotifier<double> _totalSizeMB = ValueNotifier<double>(0);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCachedImages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cachedFiles.dispose();
    _isLoading.dispose();
    _totalSizeMB.dispose();
    super.dispose();
  }

  Future<void> _loadCachedImages() async {
    _isLoading.value = true;
    try {
      final cacheDir = await getTemporaryDirectory();
      final directory = Directory(
        '${cacheDir.path}/${ProfileImageCacheManager.key}',
      );
      if (await directory.exists()) {
        final List<FileSystemEntity> entities = await directory.list().toList();
        final List<File> files = entities.whereType<File>().toList();
        int size = 0;
        for (var file in files) {
          size += await file.length();
        }
        _cachedFiles.value = files;
        _totalSizeMB.value = size / (1024 * 1024);
      } else {
        _cachedFiles.value = [];
        _totalSizeMB.value = 0;
      }
    } catch (e) {
      debugPrint('[DevTools] Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _clearAll() async {
    try {
      await _cacheManager.emptyCache();
      final cacheDir = await getTemporaryDirectory();
      final directory = Directory(
        '${cacheDir.path}/${ProfileImageCacheManager.key}',
      );
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      await _loadCachedImages();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
      }
    } catch (e) {
      debugPrint('[DevTools] Error: $e');
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      await _loadCachedImages();
    } catch (e) {
      debugPrint('[DevTools] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = DevToolsAuthController();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: JumpToBottomFAB(
        scrollController: _scrollController,
      ),
      body: Column(
        children: [
          _buildHeader(authController),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, loading, _) {
                if (loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }

                return ValueListenableBuilder<List<File>>(
                  valueListenable: _cachedFiles,
                  builder: (context, files, _) {
                    if (files.isEmpty) {
                      return Center(
                        child: Text(
                          'No cached profile images',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: Dimen.s14,
                          ),
                        ),
                      );
                    }
                    return _buildGrid(files, authController);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DevToolsAuthController authController) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Dimen.w16, vertical: Dimen.h8),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cached Images',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Dimen.s13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _totalSizeMB,
                builder: (context, size, _) {
                  return Text(
                    '${_cachedFiles.value.length} files • ${size.toStringAsFixed(2)} MB',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: Dimen.s11,
                    ),
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.blueAccent,
              size: Dimen.h20,
            ),
            onPressed: _loadCachedImages,
          ),
          if (authController.isDeveloper)
            IconButton(
              icon: Icon(
                Icons.delete_sweep,
                color: Colors.redAccent,
                size: Dimen.h20,
              ),
              onPressed: _clearAll,
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<File> files, DevToolsAuthController authController) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(Dimen.w8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Dimen.w8,
        mainAxisSpacing: Dimen.h8,
        childAspectRatio: 0.8,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _ImageTile(
          file: file,
          onDelete: authController.isDeveloper ? () => _deleteFile(file) : null,
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  final File file;
  final VoidCallback? onDelete;

  const _ImageTile({required this.file, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(Dimen.r8),
              image: DecorationImage(
                image: FileImage(file),
                fit: BoxFit.cover,
                onError: (e, s) =>
                    const Icon(Icons.broken_image, color: Colors.white24),
              ),
            ),
            child: onDelete != null
                ? Stack(
                    children: [
                      Positioned(
                        top: Dimen.h4,
                        right: Dimen.w4,
                        child: GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: EdgeInsets.all(Dimen.w4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: Dimen.h14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        SizedBox(height: Dimen.h4),
        _buildSizeText(),
      ],
    );
  }

  Widget _buildSizeText() {
    return FutureBuilder<int>(
      future: file.length(),
      builder: (context, snapshot) {
        final size = snapshot.data ?? 0;
        return Text(
          '${(size / 1024).toStringAsFixed(1)} KB',
          style: TextStyle(color: Colors.white38, fontSize: Dimen.s10),
        );
      },
    );
  }
}
