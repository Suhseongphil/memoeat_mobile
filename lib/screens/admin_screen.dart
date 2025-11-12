import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/supabase.dart';
import '../models/user_approval.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<UserApproval> _pendingUsers = [];
  List<UserApproval> _approvedUsers = [];
  bool _isLoading = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SupabaseConfig.client
          .from('user_approvals')
          .select()
          .order('requested_at', ascending: false);

      final allUsers = (response as List)
          .map((json) => UserApproval.fromJson(json))
          .toList();

      setState(() {
        _pendingUsers = allUsers.where((u) => !u.isApproved).toList();
        _approvedUsers = allUsers.where((u) => u.isApproved).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Future<void> _approveUser(String userId, String email) async {
    try {
      final currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser == null) return;

      await SupabaseConfig.client
          .from('user_approvals')
          .update({
            'is_approved': true,
            'approved_at': DateTime.now().toIso8601String(),
            'approved_by': currentUser.id,
          })
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$email 사용자가 승인되었습니다.')),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Future<void> _rejectUser(String userId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 거절'),
        content: Text('$email 사용자를 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseConfig.client
            .from('user_approvals')
            .delete()
            .eq('user_id', userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$email 사용자가 거절되었습니다.')),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tabs
                TabBar(
                  tabs: const [
                    Tab(text: '승인 대기'),
                    Tab(text: '승인된 사용자'),
                  ],
                  onTap: (index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                ),

                // Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _buildPendingUsersList(),
                      _buildApprovedUsersList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPendingUsersList() {
    if (_pendingUsers.isEmpty) {
      return const Center(
        child: Text('승인 대기 중인 사용자가 없습니다'),
      );
    }

    return ListView.builder(
      itemCount: _pendingUsers.length,
      itemBuilder: (context, index) {
        final user = _pendingUsers[index];
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
        final requestedAt = dateFormat.format(user.requestedAt);

        return ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(user.email),
          subtitle: Text('요청일: $requestedAt'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _approveUser(user.userId, user.email),
                child: const Text('승인'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _rejectUser(user.userId, user.email),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('거절'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApprovedUsersList() {
    if (_approvedUsers.isEmpty) {
      return const Center(
        child: Text('승인된 사용자가 없습니다'),
      );
    }

    return ListView.builder(
      itemCount: _approvedUsers.length,
      itemBuilder: (context, index) {
        final user = _approvedUsers[index];
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
        final approvedAt = user.approvedAt != null
            ? dateFormat.format(user.approvedAt!)
            : '';

        return ListTile(
          leading: const Icon(Icons.person, color: Colors.green),
          title: Text(user.email),
          subtitle: Text(approvedAt.isNotEmpty ? '승인일: $approvedAt' : ''),
        );
      },
    );
  }
}

