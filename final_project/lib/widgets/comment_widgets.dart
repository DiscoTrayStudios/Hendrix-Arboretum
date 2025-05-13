import 'package:flutter/widgets.dart';
import 'package:safe_text/safe_text.dart';
import 'package:final_project/objects/comment.dart';
import 'package:flutter/material.dart';
import 'package:final_project/widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:final_project/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';


class CommentSection extends StatefulWidget {
  const CommentSection({super.key, required this.addComment, required this.treeID});

  final Future<void> Function(int id, String comment) addComment;
  //final Future<List<Comment>> Function(int id) getComment;
  //final Future<List<Comment>> comments;
  final int treeID;

  @override
  State<CommentSection> createState() => _CommentSectionState();
}


class _CommentSectionState extends State<CommentSection> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>(debugLabel: '_CommentSectionState');
  List<Comment> _comments = [];
  
  @override
  void initState() {
    super.initState();
    _fetchcmts();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchcmts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final _firestore = FirebaseFirestore.instance;
      try {
        QuerySnapshot snapshot = await _firestore
          .collection('treeComments')
          .doc(widget.treeID.toString())
          .collection('comments')
          .get();
        
        if (snapshot.size > 0) {
          _comments = snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
          _comments.sort((a, b) => b.time.compareTo(a.time));
          
          // Check if widget is still mounted before calling setState
          if (mounted) {
            setState(() {});
          }
        }
      } catch (e) {
        // Handle any errors, still checking mounted status
        if (mounted) {
          // Optionally update state to show error
        }
      }
    }
  }
 
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer<ApplicationState>(
            builder: (context, appState, _)=> 
            Form(key: _formKey, child: Row(
              children: [
                if(appState.loggedIn)...[
                  Expanded(child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Leave a comment',
          ),
          validator: (value) {
            if(value == null || value.isEmpty){
              return 'Enter your message to continue';
            }
            return null;
          },
        )),
        StyledButton(child: Text('post'), 
        onPressed: () async {
          if(_formKey.currentState != null){
            if(_formKey.currentState!.validate()){
              if(await SafeText.containsBadWord(text: _controller.text)){
                // Potentially show bad word error
              }
              else{
                await widget.addComment(widget.treeID, _controller.text);
                // Check mounted before fetching comments again
                if (mounted) {
                  await _fetchcmts();
                  _controller.clear();
                }
              }
            }
          }
        })
                ]
              ],
            ), 
          ),

          ),
        const SizedBox(height: 20),
        
        Consumer<ApplicationState>(
            builder: (context, appState, _)=> Column(children: [
              if(appState.loggedIn)...[
                ListView.separated(
                  separatorBuilder: (BuildContext context, int index){
                    return SizedBox(height: 5);
                  },
                  shrinkWrap: true, itemCount: _comments.length, 
                  itemBuilder: (context, index){
                    if(!appState.blockedUsers.contains(_comments[index].userid)){
                      return ColoredBox(
                        color: Colors.white, 
                        child: Column(children: [
                          ListTile(
                            isThreeLine: true, 
                            visualDensity: VisualDensity(horizontal: 3, vertical: 3),
                            title: Text('${_comments[index].name}', style: TextStyle(fontSize: 12),), 
                            subtitle: Text('${_comments[index].message}')
                          ),
                          Row(children: [
                            Expanded(child: Container()), 
                            if(FirebaseAuth.instance.currentUser?.uid == _comments[index].userid)...[
                              StyledButton(
                                onPressed: () {
                                  showDialog(
                                    context: context, 
                                    builder: (_) {
                                      return AlertDialog(
                                        title: Text('Delete comment?'),
                                        content: Text('Would you like to delete this comment?'),
                                        actions: [
                                          StyledButton(
                                            child: Text('Cancel'), 
                                            onPressed: () { 
                                              Navigator.of(context).pop(); 
                                            }
                                          ),
                                          StyledButton(
                                            child: Text('Delete'), 
                                            onPressed: () async {
                                              await appState.deleteComment(widget.treeID, _comments[index]);
                                              Navigator.of(context).pop();
                                              
                                              // Check if mounted before updating
                                              if (mounted) {
                                                await _fetchcmts();
                                              }
                                            }
                                          )
                                        ],
                                      );
                                    }
                                  );
                                }, 
                                child: Icon(Icons.delete)
                              )
                            ] else...[
                              StyledButton(
                                onPressed: () {
                                  showDialog(
                                    context: context, 
                                    builder: (_) {
                                      return AlertDialog(
                                        title: Text('Report comment?'),
                                        content: Text('Would you like to block this user and hide all of their comments?'),
                                        actions: [
                                          StyledButton(
                                            child: Text('Report'), 
                                            onPressed: () { 
                                              appState.reportComment(widget.treeID, _comments[index]); 
                                              Navigator.of(context).pop();
                                            }
                                          ),
                                          StyledButton(
                                            child: Text('Report and block'), 
                                            onPressed: () async {
                                              await appState.reportComment(widget.treeID, _comments[index]);
                                              await appState.blockUser(_comments[index].userid); 
                                              Navigator.of(context).pop();
                                              
                                              // Check if mounted before updating
                                              if (mounted) {
                                                await _fetchcmts();
                                              }
                                            }
                                          )
                                        ],
                                      );
                                    }
                                  );
                                }, 
                                child: Icon(Icons.report)
                              )
                            ]
                          ],)
                        ])
                      );
                    } else {
                      return SizedBox.shrink(); // For blocked users
                    }
                  } 
                )
              ] else...[
                const Text('Sign in to see comments!')
              ]
            ],)),
      ],
    );
  }
}

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key, required this.onReportComment, required this.onBlockUser, required this.userid, required this.treeid, required this.comment});
  final Future<void> Function(int id, Comment comment) onReportComment;
  final Future<void> Function(String id) onBlockUser;
  final String userid;
  final int treeid;
  final Comment comment;
  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(title: Text('Report comment?'),
        content: Text('Would you like to block this user and hide all of their comments?'),
        actions: [
            StyledButton(
              child: Text('Report'), 
              onPressed: () async { 
                await widget.onReportComment(widget.treeid, widget.comment); 
                Navigator.of(context).pop();
              }
            ),
            StyledButton(
              child: Text('Report and block'), 
              onPressed: () async { 
                await widget.onReportComment(widget.treeid, widget.comment);
                await widget.onBlockUser(widget.userid); 
                
                // Check if mounted before calling setState
                if (mounted) {
                  setState(() {});
                }
                Navigator.of(context).pop();
              }
            )
        ],
    );
  }
}