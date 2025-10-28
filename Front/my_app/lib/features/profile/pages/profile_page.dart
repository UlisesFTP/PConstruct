import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';

// --- INICIO DE MODELOS DE DATOS (Mantenidos en este archivo por ahora) ---
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
// --- FIN DE MODELOS DE DATOS ---

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- DATOS MOCK (Tomados de tu ejemplo) ---
  final List<BuildItem> builds = [
    BuildItem(
      title: 'Gaming PC Build',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBOhjB2lM8_KNzqgZ_UZG1ZiTgnImvf0iTTBJHzz4ZJfWp54NhbhGNkmeCxU6MHJUBIdLxqGKGNrU5lW0H6cwBiiz8Q_i14pzXsWkpCYpgujITzwdb4jvMSZ-nRmjGYCTp_46XdMLoijeNzRfo4dvOmGuYoU9bzwTcasG0wLMbZqB8x4opqj8MU6-MAkIHuOPhFpZ4GjdovizaDRq7w0kxk_-GVfoMmEKvSUFhWhXmIbw0dhI5ftD9CSBYnZSoV7XaGfEW19o0CNrU',
    ),
    BuildItem(
      title: 'Streaming Setup',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAheOpjHot45ixTcE6oH0gv7qGDl0tJ6Jx3VQGv0y0HeCY_f62LbMk6KO1woLzH8TbIETI_POcPJX9IXQO7SH9X83DqHX8635xnmPzJtSVfZ6R7c_s6ZTUrdNclns6AJzlA9uMPv0uC92JrQ7Aw-csevwJRxhQN2-rSIsY6BoMuZUSh3WTKKWX1SLjZu6ASfp3VQoArynTFYm-tS67DHhzQb4JX43DL9L2j0sl_RkNy8ICnNJTFMLus0NW624xd98AShUZKqLGCTxo',
    ),
    BuildItem(
      title: 'Workstation Build',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDmX3WDw--Z2jr62e2t4bWlfx9dliJY9M34de64tUTJsnLaohN_mGHMWlVTe3G13A1PNplwZUL4DBTIOrftuhlLkRgSXfsEShf7GQJxM0vRXEiJCePCYHL2SY_WOOMp3rbJnBx5PGH5qSyaMYEPe9EoMzXXkCOB_6SQywjmB04fgyESzId8k0VE-JwHJDgPtwOa7KGKspXxtk4lX_pzQOyN_2sZOmLvnjTZReIeog6s7B5SHC44qd_oGtXyNqjWkSnNpFY2RLCOSWw',
    ),
  ];

  final List<PostItem> posts = [
    PostItem(
      timeAgo: 'hace 2 días',
      title: 'Nueva build para gaming y streaming',
      description:
          'Mira mi última build, optimizada tanto para gaming como para streaming. ¡Déjame saber qué piensas!',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA3wKndLEfWphcbQj40cAA6uVctDJZIR_fzqaxkO-_rbJrW9DnNMuOQjY56F9x79Y9gffeBIvWjrVq-IqzyvwbTNWhZ_RVBYYkYKQxY7oZ7FXZGMEamWnPLqMb2Dov8Q5v1US0lBaM09nnhGSPJEi3GO9koSOZ_4tDizWpMUNNR0NNQoxEZIW2XiB1sVrI8rsb3EKQcOH-I3nlqo9mCwJ9T3TdH9PCt_50GmbfNwe7Hr-vnz7huYk4qaedTSsS0Tc_t0ES5QV2vP4g',
    ),
    PostItem(
      timeAgo: 'hace 1 semana',
      title: 'Mejor PC gaming económica',
      description:
          '¿Buscas una PC gaming económica? Aquí está mi recomendación para una configuración potente pero asequible.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA_0uQwbSzLRnYNAlTaxdOuaZUhDBhVNQKpITcUtGGefUZqzbcBjfG1LJ0tXfPsh1dR-i0uGbTcYLedSkVBp_i7JT3Kab96w18Mv9yAmQEr-eV0go_JV9DF9hoYhMjeTDgBapjbGjFq1Z4x0OyfDlP3bpS-UPPeofqzIip_lC2SrGX5E26NnZWMZ4YxXCsn8J9HbRluSnwSkpyq2JOEnndWRZc4iIMGRi8W6Kj4qIQq3DXxTta4yOdNEXCFE7-6m_rGIESPb9k7gJ0',
    ),
  ];
  // --- FIN DATOS MOCK ---

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario del AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    // NO usamos Scaffold, MainLayout ya lo proporciona.
    // Devolvemos directamente el contenido de la página.
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
              // Header del perfil (conectado al AuthProvider)
              ProfileHeader(user: user),
              const SizedBox(height: 24),

              // Estadísticas
              StatsRow(),
              const SizedBox(height: 32),

              // Mis Builds
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

              // Mis Publicaciones
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

// --- WIDGETS DE PERFIL (Basados en tu nuevo diseño) ---

class ProfileHeader extends StatelessWidget {
  final User? user; // Recibe el usuario del AuthProvider
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
              // Avatar
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC7384D), width: 3),
                  image: const DecorationImage(
                    // TODO: Reemplazar con user?.avatarUrl cuando exista
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDwns93uToiC8Lh4Chj4POopDnEG27co1Eu6GWBzMl5NAy6SACXnc5JgjBugBqkZJDUGzYlh47-C2AN9TbebzzMIaMuWz8d_Cpar1B6AW-HdgDUafhgVVRDEkX6D6SMHKzjyB8Stoxq-z1YO0jSmnVgpB84Yhx_TI5Ji-YS1wrS_mt7CdN2fbRHZLAg544dQTUHlne-3XLkImG0aPdV5J3aGlJJEDtFWaNKMVc37EcPN6u6QvNoPVAniC8kRHQmgjMj5kCUIenpUjo',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nombre (del AuthProvider)
              Text(
                user?.username ?? 'Nombre de Usuario', // Dato dinámico
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Username (del AuthProvider)
              Text(
                '@${user?.username ?? 'username'}', // Dato dinámico
                style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 16),
              ),
              const SizedBox(height: 4),

              // Fecha (TODO: Hacer dinámico en el futuro)
              const Text(
                'Miembro desde 2021',
                style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Botón Editar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implementar navegación a /profile/edit
                  },
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
        // TODO: Conectar estos números a datos reales
        Expanded(
          child: StatCard(number: '12', label: 'Builds'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatCard(number: '34', label: 'Posts'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatCard(number: '56', label: 'Seguidores'),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BuildsGrid extends StatelessWidget {
  final List<BuildItem> builds;

  const BuildsGrid({super.key, required this.builds});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: builds.length,
      itemBuilder: (context, index) {
        return BuildCard(buildItem: builds[index]);
      },
    );
  }
}

class BuildCard extends StatelessWidget {
  final BuildItem buildItem;

  const BuildCard({super.key, required this.buildItem});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    buildItem.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  buildItem.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostsList extends StatelessWidget {
  final List<PostItem> posts;

  const PostsList({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: posts.map((post) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PostCard(post: post),
        );
      }).toList(),
    );
  }
}

class PostCard extends StatelessWidget {
  final PostItem post;

  const PostCard({super.key, required this.post});

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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.timeAgo,
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
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.description,
                      style: const TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 14,
                        height: 1.5,
                      ),
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
                    child: Image.network(post.imageUrl, fit: BoxFit.cover),
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
