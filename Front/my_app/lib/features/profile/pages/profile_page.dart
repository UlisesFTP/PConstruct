import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<BuildItem> builds = [];
  final List<PostItem> posts = [];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 24,
        vertical: 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              ProfileHeader(user: user),
              const SizedBox(height: 24),
              StatsRow(),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mis Builds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              BuildsGrid(builds: builds),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mis Publicaciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PostsList(posts: posts),
            ],
          ),
        ),
      ),
    );
  }
}

class BuildItem {
  final String title;
  final String imageUrl;
  BuildItem({required this.title, required this.imageUrl});
}

class PostItem {
  final String timeAgo;
  final String title;
  final String description;
  final String imageUrl;
  PostItem({
    required this.timeAgo,
    required this.title,
    required this.description,
    required this.imageUrl,
  });
}

class ProfileHeader extends StatelessWidget {
  final User? user;
  const ProfileHeader({super.key, this.user});

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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC7384D), width: 3),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDwns93uToiC8Lh4Chj4POopDnEG27co1Eu6GWBzMl5NAy6SACXnc5JgjBugBqkZJDUGzYlh47-C2AN9TbebzzMIaMuWz8d_Cpar1B6AW-HdgDUafhgVVRDEkX6D6SMHKzjyB8Stoxq-z1YO0jSmnVgpB84Yhx_TI5Ji-YS1wrS_mt7CdN2fbRHZLAg544dQTUHlne-3XLkImG0aPdV5J3aGlJJEDtFWaNKMVc37EcPN6u6QvNoPVAniC8kRHQmgjMj5kCUIenpUjo',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.username ?? 'Nombre de Usuario',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user?.username ?? 'username'}',
                style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Miembro desde 2021',
                style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC7384D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Editar Perfil',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
  const StatsRow({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: StatCard(number: '12', label: 'Builds'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatCard(number: '34', label: 'Posts'),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String number;
  final String label;
  const StatCard({super.key, required this.number, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class BuildsGrid extends StatelessWidget {
  final List<BuildItem> builds;
  const BuildsGrid({super.key, required this.builds});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: builds.length,
      itemBuilder: (context, index) {
        return Container();
      },
    );
  }
}

class PostsList extends StatelessWidget {
  final List<PostItem> posts;
  const PostsList({super.key, required this.posts});
  @override
  Widget build(BuildContext context) {
    return Column();
  }
}
