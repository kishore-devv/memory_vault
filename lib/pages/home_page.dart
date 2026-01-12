import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:memory_vault/pages/add_memory_page.dart';
import 'package:memory_vault/pages/chat_page.dart';
import 'package:memory_vault/services/memory_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: MemoryService().getMyMemories(),
          builder: (context, snapshot) {
            final memories = snapshot.data ?? [];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return CustomScrollView(
              slivers: [
                // Premium Sliver App Bar
                SliverAppBar(
                  expandedHeight: 220.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
                    title: Text(
                      'Memory Vault',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    centerTitle: false,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFBB86FC).withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 180,
                            color: const Color(0xFFBB86FC).withOpacity(0.05),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          top: 80,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hello,",
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Your digital brain is ready",
                                style: GoogleFonts.inter(
                                  color: Colors.white30,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white60,
                        ),
                        onPressed:
                            () => Supabase.instance.client.auth.signOut(),
                      ),
                    ),
                  ],
                ),

                // Content
                if (isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (memories.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bubble_chart_outlined,
                            size: 80,
                            color: Colors.white12,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your vault is empty',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              color: Colors.white30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to store your first memory',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final memory = memories[index];
                        final date =
                            memory['created_at'] != null
                                ? DateTime.parse(memory['created_at']).toLocal()
                                : DateTime.now();

                        return _buildMemoryCard(memory['content'] ?? '', date);
                      }, childCount: memories.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildMemoryCard(String content, DateTime date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Colors.white38,
                ),
                const SizedBox(width: 6),
                Text(
                  "${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: "chat_btn",
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              ),
          label: Text(
            'Ask Vault',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          icon: const Icon(Icons.psychology_outlined, size: 28),
          backgroundColor: const Color(0xFF03DAC6),
          foregroundColor: Colors.black,
          elevation: 4,
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: "add_btn",
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMemoryPage()),
              ),
          backgroundColor: const Color(0xFFBB86FC),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          child: const Icon(Icons.add_rounded, size: 36),
        ),
      ],
    );
  }
}
