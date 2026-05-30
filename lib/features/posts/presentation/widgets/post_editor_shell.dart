// lib/features/posts/presentation/widgets/post_editor_shell.dart (Alternative)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/posts_controller.dart';
import 'post_form_page.dart';

class PostEditorShell extends StatelessWidget {
  final String? postId;

  const PostEditorShell({super.key, this.postId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PostsController(),
      child: _PostEditorContent(postId: postId),
    );
  }
}

class _PostEditorContent extends StatelessWidget {
  final String? postId;

  const _PostEditorContent({required this.postId});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PostsController>();
    final post = postId != null
        ? controller.posts.firstWhere(
            (p) => p.id == postId,
            orElse: () => throw Exception('Post not found'),
          )
        : null;

    return PostFormPage(
      post: post,
      controller: controller,
    );
  }
}
