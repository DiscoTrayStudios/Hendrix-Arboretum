import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_project/widgets/widgets.dart';

class PersonalNoteSection extends StatefulWidget {
  const PersonalNoteSection({super.key, required this.treeID});

  final int treeID;

  @override
  State<PersonalNoteSection> createState() => _PersonalNoteSectionState();
}

class _PersonalNoteSectionState extends State<PersonalNoteSection> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>(debugLabel: '_PersonalNoteSectionState');
  String _currentNote = '';
  bool _hasNote = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNote();
  }

  Future<void> _fetchNote() async {
    setState(() {
      _isLoading = true;
    });
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore
          .collection('userNotes')
          .doc(user.uid)
          .collection('trees')
          .doc(widget.treeID.toString());
          
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('note')) {
          setState(() {
            _currentNote = data['note'];
            _controller.text = _currentNote;
            _hasNote = true;
            _isLoading = false;
          });
          return;
        }
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveNote(String note) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('userNotes')
          .doc(user.uid)
          .collection('trees')
          .doc(widget.treeID.toString())
          .set({
        'note': note,
        'treeID': widget.treeID,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _currentNote = note;
        _hasNote = true;
      });
    }
  }

  Future<void> _deleteNote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('userNotes')
          .doc(user.uid)
          .collection('trees')
          .doc(widget.treeID.toString())
          .delete();
      
      setState(() {
        _currentNote = '';
        _controller.clear();
        _hasNote = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Personal Notes', 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 103, 79)
            )
        ),
        const SizedBox(height: 10),
        Form(
          key: _formKey, 
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add your personal note about this tree',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your note to continue';
                    }
                    return null;
                  },
                )
              ),
              StyledButton(
                child: Text(_hasNote ? 'Update' : 'Save'), 
                onPressed: () async {
                  if (_formKey.currentState != null) {
                    if (_formKey.currentState!.validate()) {
                      await _saveNote(_controller.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Note saved successfully!'),
                          backgroundColor: Color.fromARGB(255, 0, 103, 79),
                        ),
                      );
                    }
                  }
                }
              )
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 0, 103, 79),
            ),
          )
        else if (_hasNote)
          ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  isThreeLine: false,
                  visualDensity: const VisualDensity(horizontal: 3, vertical: 3),
                  title: const Text('Your personal note', style: TextStyle(fontSize: 12)),
                  subtitle: Text(_currentNote),
                ),
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    StyledButton(
                      onPressed: () {
                        showDialog(
                          context: context, 
                          builder: (_) {
                            return AlertDialog(
                              title: const Text('Delete note?'),
                              content: const Text('Would you like to delete this note?'),
                              actions: [
                                StyledButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  }
                                ),
                                StyledButton(
                                  child: const Text('Delete'),
                                  onPressed: () {
                                    _deleteNote();
                                    Navigator.of(context).pop();
                                  }
                                )
                              ],
                            );
                          }
                        );
                      },
                      child: const Icon(Icons.delete)
                    )
                  ],
                )
              ]
            )
          )
      ],
    );
  }
}