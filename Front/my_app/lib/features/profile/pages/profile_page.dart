import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/posts.dart';
import 'package:my_app/models/build.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:my_app/core/widgets/profile_picture_modal.dart';

class ProfileData {
  final List<Post> posts;
  final List<BuildSummary> builds;

  ProfileData({required this.posts, required this.builds});
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<ProfileData> _profileDataFuture;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    timeago.setLocaleMessages('es_short', timeago.EsShortMessages());
    _loadProfileData();
  }

  void _loadProfileData() {
    setState(() {
      _profileDataFuture = _fetchData();
    });
  }

  Future<ProfileData> _fetchData() async {
    try {
      final results = await Future.wait([
        _apiClient.getMyPosts(),
        _apiClient.getMyBuilds(),
      ]);

      final posts = results[0] as List<Post>;
      final builds = results[1] as List<BuildSummary>;

      return ProfileData(posts: posts, builds: builds);
    } catch (e) {
      throw Exception('Error al cargar datos del perfil: $e');
    }
  }

  void _showEditProfileModal(BuildContext context, User currentUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EditProfileModal(
          apiClient: _apiClient,
          user: currentUser,
          onProfileUpdated: () {},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return FutureBuilder<ProfileData>(
      future: _profileDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFC7384D)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[400],
                    size: isMobile ? 56 : 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: isMobile ? 13 : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadProfileData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC7384D),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 24,
                        vertical: isMobile ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final profileData = snapshot.data!;
        final allPosts = profileData.posts;
        final allBuilds = profileData.builds;

        final int postCount = allPosts.length;
        final int buildCount = allBuilds.length;

        final sortedPosts = List<Post>.from(allPosts);
        sortedPosts.sort(
          (a, b) => (b.likesCount + b.commentsCount).compareTo(
            a.likesCount + a.commentsCount,
          ),
        );
        final topPosts = sortedPosts.take(4).toList();
        final topBuilds = allBuilds.take(4).toList();

        return RefreshIndicator(
          onRefresh: () async {
            _loadProfileData();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: const Color(0xFFC7384D),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : (isTablet ? 32 : 40),
              vertical: isMobile ? 16 : 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 800 : 960),
                child: Column(
                  children: [
                    ProfileHeader(
                      user: user,
                      isMobile: isMobile,
                      onEditPressed: () {
                        if (user != null) {
                          _showEditProfileModal(context, user);
                        }
                      },
                    ),
                    SizedBox(height: isMobile ? 20 : 24),

                    StatsRow(
                      buildCount: buildCount,
                      postCount: postCount,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 24 : 32),

                    _buildSectionHeader(
                      context,
                      title: 'Mis Builds',
                      isMobile: isMobile,
                      onViewAllPressed: () =>
                          Navigator.pushNamed(context, '/my-builds'),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    BuildsGrid(builds: topBuilds, isMobile: isMobile),
                    SizedBox(height: isMobile ? 24 : 32),

                    _buildSectionHeader(
                      context,
                      title: 'Mis Publicaciones',
                      isMobile: isMobile,
                      onViewAllPressed: () =>
                          Navigator.pushNamed(context, '/my-posts'),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    PostsList(posts: topPosts, isMobile: isMobile),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onViewAllPressed,
    required bool isMobile,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onViewAllPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 4 : 8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ver todos',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: isMobile ? 12 : 14,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final User? user;
  final VoidCallback onEditPressed;
  final bool isMobile;

  const ProfileHeader({
    super.key,
    this.user,
    required this.onEditPressed,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider avatarImage =
        (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
        ? NetworkImage(user!.avatarUrl!)
        : const NetworkImage(
                'https://static.vecteezy.com/system/resources/previews/009/734/564/original/default-avatar-profile-icon-of-social-media-user-vector.jpg',
              )
              as ImageProvider;

    final avatarSize = isMobile ? 100.0 : 128.0;
    final nameFontSize = isMobile ? 20.0 : 22.0;
    final usernameFontSize = isMobile ? 14.0 : 16.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          child: Column(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC7384D), width: 3),
                  image: DecorationImage(image: avatarImage, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              Text(
                user?.name ?? user?.username ?? 'Nombre de Usuario',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              Text(
                '@${user?.username ?? 'username'}',
                style: TextStyle(
                  color: const Color(0xFFA0A0A0),
                  fontSize: usernameFontSize,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                'Miembro desde 2021',
                style: TextStyle(
                  color: const Color(0xFFA0A0A0),
                  fontSize: usernameFontSize,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onEditPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC7384D),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Editar Perfil',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final int buildCount;
  final int postCount;
  final bool isMobile;

  const StatsRow({
    super.key,
    required this.buildCount,
    required this.postCount,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            number: buildCount.toString(),
            label: 'Builds',
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: StatCard(
            number: postCount.toString(),
            label: 'Posts',
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String number;
  final String label;
  final bool isMobile;

  const StatCard({
    super.key,
    required this.number,
    required this.label,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 12 : 16,
            horizontal: isMobile ? 8 : 12,
          ),
          child: Column(
            children: [
              Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFFA0A0A0),
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BuildsGrid extends StatelessWidget {
  final List<BuildSummary> builds;
  final bool isMobile;

  const BuildsGrid({super.key, required this.builds, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    if (builds.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 32.0 : 40.0),
          child: Column(
            children: [
              Icon(
                Icons.precision_manufacturing_outlined,
                size: isMobile ? 56 : 64,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                'Aún no has creado ninguna build.',
                style: TextStyle(
                  color: const Color(0xFFA0A0A0),
                  fontSize: isMobile ? 14 : 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: builds.map((build) {
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
          child: BuildCard(buildItem: build, isMobile: isMobile),
        );
      }).toList(),
    );
  }
}

class BuildCard extends StatelessWidget {
  final BuildSummary buildItem;
  final bool isMobile;

  const BuildCard({super.key, required this.buildItem, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.precision_manufacturing,
                color: Theme.of(context).primaryColor,
                size: isMobile ? 28 : 32,
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buildItem.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    _BuildSpec(
                      icon: Icons.memory,
                      value: buildItem.cpuName ?? 'N/A',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 4),
                    _BuildSpec(
                      icon: Icons.developer_board,
                      value: buildItem.gpuName ?? 'N/A',
                      isMobile: isMobile,
                    ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? 8 : 16),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[600],
                size: isMobile ? 14 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildSpec extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isMobile;

  const _BuildSpec({
    required this.icon,
    required this.value,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFA0A0A0), size: isMobile ? 14 : 16),
        SizedBox(width: isMobile ? 6 : 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: const Color(0xFFE0E0E0),
              fontSize: isMobile ? 12 : 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class PostsList extends StatelessWidget {
  final List<Post> posts;
  final bool isMobile;

  const PostsList({super.key, required this.posts, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 32.0 : 40.0),
          child: Column(
            children: [
              Icon(
                Icons.article_outlined,
                size: isMobile ? 56 : 64,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                'Aún no has creado ninguna publicación.',
                style: TextStyle(
                  color: const Color(0xFFA0A0A0),
                  fontSize: isMobile ? 14 : 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: posts.map((post) {
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
          child: ProfilePostCard(post: post, isMobile: isMobile),
        );
      }).toList(),
    );
  }
}

class ProfilePostCard extends StatelessWidget {
  final Post post;
  final bool isMobile;

  const ProfilePostCard({super.key, required this.post, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        post.imageUrl ??
        'https://via.placeholder.com/300x200.png?text=No+Image';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeago.format(post.createdAt, locale: 'es_short'),
                      style: const TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (post.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black.withOpacity(0.3),
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Color(0xFFA0A0A0),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      post.content,
                      style: const TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeago.format(post.createdAt, locale: 'es_short'),
                            style: const TextStyle(
                              color: Color(0xFFA0A0A0),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.content,
                            style: const TextStyle(
                              color: Color(0xFFA0A0A0),
                              fontSize: 14,
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black.withOpacity(0.3),
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Color(0xFFA0A0A0),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EditProfileModal extends StatefulWidget {
  final User user;
  final ApiClient apiClient;
  final VoidCallback onProfileUpdated;

  const _EditProfileModal({
    required this.user,
    required this.apiClient,
    required this.onProfileUpdated,
  });

  @override
  State<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<_EditProfileModal> {
  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _avatarUrl = widget.user.avatarUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showProfilePictureModal() async {
    final String? newUrl = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfilePictureModal(apiClient: widget.apiClient),
    );

    if (newUrl != null && newUrl.isNotEmpty) {
      setState(() {
        _avatarUrl = newUrl;
      });
    }
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final updatedUserResponse = await widget.apiClient.updateUser(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        avatarUrl: _avatarUrl,
      );

      if (!mounted) return;

      Provider.of<AuthProvider>(
        context,
        listen: false,
      ).updateUser(updatedUserResponse);

      Navigator.of(context).pop();
      widget.onProfileUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado con éxito.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: isMobile ? 20 : 24,
          right: isMobile ? 20 : 24,
          top: isMobile ? 20 : 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Editar Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 22 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),

            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 45 : 50,
                    backgroundColor: const Color(0xFF2A2A2A),
                    backgroundImage:
                        (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                        ? NetworkImage(_avatarUrl!)
                        : const NetworkImage(
                                'https://static.vecteezy.com/system/resources/previews/009/734/564/original/default-avatar-profile-icon-of-social-media-user-vector.jpg',
                              )
                              as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Theme.of(context).primaryColor,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        onTap: _isLoading ? null : _showProfilePictureModal,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: isMobile ? 18 : 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),

            IgnorePointer(
              ignoring: _isLoading,
              child: Opacity(
                opacity: _isLoading ? 0.6 : 1.0,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: isMobile ? 14 : 15,
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC7384D),
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 14 : 16,
                          vertical: isMobile ? 14 : 16,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 14 : 16),
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre de Usuario',
                        labelStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: isMobile ? 14 : 15,
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC7384D),
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 14 : 16,
                          vertical: isMobile ? 14 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC7384D),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isLoading ? 0 : 2,
                  disabledBackgroundColor: const Color(
                    0xFFC7384D,
                  ).withOpacity(0.6),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      )
                    : Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 15 : 16,
                        ),
                      ),
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
          ],
        ),
      ),
    );
  }
}
