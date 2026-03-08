// ==================== IMPORTS ====================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// ==================== GLOBAL VARIABLES ====================
Map<String, dynamic>? currentUser;

// ==================== ENTRY POINT ====================
void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen()));

// ==================== GLOBAL SIDEBAR ====================
Widget _buildAppSidebar(BuildContext context) {
  return Drawer(
    backgroundColor: const Color(0xFFD9D9D9), 
    child: Column(
      children: [
        const SizedBox(height: 60),
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(padding: EdgeInsets.only(left: 20.0), child: Icon(Icons.menu, size: 30, color: Colors.black)),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _figmaMenuBtn(context, "Dashboard", Icons.dashboard_outlined),
              _figmaMenuBtn(context, "My Items", Icons.inventory_2_outlined),
              _figmaMenuBtn(context, "Department Filters", Icons.filter_list),
              _figmaMenuBtn(context, "Favorites", Icons.favorite_border),
              _figmaMenuBtn(context, "Messages", Icons.message_outlined),
              _figmaMenuBtn(context, "History", Icons.history),
              _figmaMenuBtn(context, "Report", Icons.report_gmailerrorred),
              _figmaMenuBtn(context, "Requests", Icons.notifications_none),
              const SizedBox(height: 20),
              _figmaMenuBtn(context, "Logout", Icons.logout, isLogout: true),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _figmaMenuBtn(BuildContext context, String title, IconData icon, {bool isLogout = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFFDEB00), borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        dense: true, visualDensity: const VisualDensity(vertical: -3),
        title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
        onTap: () {
          if (isLogout) {
            currentUser = null;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (route) => false);
          } else if (title == "My Items") {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MyItemsScreen()));
          } else if (title == "Dashboard") {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const DashboardScreen()));
          } else {
            Navigator.pop(context); 
          }
        },
      ),
    ),
  );
}

// ==================== DASHBOARD SCREEN ====================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List items = []; bool isLoading = true;
  @override void initState() { super.initState(); _fetchItems(); }

  Future<void> _fetchItems() async {
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:5000/api/items'));
      if (res.statusCode == 200) setState(() { items = jsonDecode(res.body); isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088), iconTheme: const IconThemeData(color: Colors.white),
        title: Container(height: 35, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const TextField(decoration: InputDecoration(hintText: "Search", prefixIcon: Icon(Icons.search), border: InputBorder.none))),
        actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())), icon: const Icon(Icons.account_circle, size: 30))],
      ),
      drawer: _buildAppSidebar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.all(20), child: Text("Dashboard", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A0088)))),
          Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : items.isEmpty ? const Center(child: Text("No items found.")) : ListView.builder(itemCount: items.length, itemBuilder: (c, i) => _itemCard(items[i]))),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (c) => const AddItemScreen())); _fetchItems(); },
        backgroundColor: const Color(0xFFFDEB00), label: const Text("Add Item", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _itemCard(dynamic item) {
    String? imgPath = item['image']; bool hasImage = imgPath != null && imgPath.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null), child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null),
          const SizedBox(width: 15),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['owner'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Text(item['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("Qty: ${item['quantity']} | Cond: ${item['condition']}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text(item['status'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Row(children: [
                _miniBtn("Read", Colors.white, () {}), const SizedBox(width: 10), _miniBtn("Borrow", Colors.yellow, () {})
              ])
            ],
          ))
        ],
      ),
    );
  }
}

// ==================== MY ITEMS SCREEN (VAVT-40) ====================
class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});
  @override State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  List items = []; bool isLoading = true;
  @override void initState() { super.initState(); _fetchMyItems(); }

  Future<void> _fetchMyItems() async {
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:5000/api/items/user/${currentUser!['id']}'));
      if (res.statusCode == 200) setState(() { items = jsonDecode(res.body); isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }

  Future<void> _deleteItem(int id) async {
    try {
      await http.delete(Uri.parse('http://10.0.2.2:5000/api/items/$id'));
      _fetchMyItems(); // Re-fetches, which will trigger Empty State if 0 items left
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete failed"))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088), iconTheme: const IconThemeData(color: Colors.white),
        title: Container(height: 35, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const TextField(decoration: InputDecoration(hintText: "Search", prefixIcon: Icon(Icons.search), border: InputBorder.none))),
        actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())), icon: const Icon(Icons.account_circle, size: 30))],
      ),
      drawer: _buildAppSidebar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.all(20), child: Text("My Items", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A0088)))),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : items.isEmpty 
                  ? _emptyStateFigma() // VAVT-40: New Empty State
                  : ListView.builder(itemCount: items.length, itemBuilder: (c, i) => _MyItemCard(
                      item: items[i], 
                      onDeleteConfirm: () => _deleteItem(items[i]['id']),
                      onUpdateTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (c) => EditItemScreen(item: items[i]))); _fetchMyItems(); }
                    )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (c) => const AddItemScreen())); _fetchMyItems(); },
        backgroundColor: const Color(0xFFFDEB00), label: const Text("Add Item", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Matches Figma "No Items Found" screen
  Widget _emptyStateFigma() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.block, size: 80, color: Colors.black87),
          SizedBox(height: 10),
          Text("No\nItems\nFound", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
        ],
      ),
    );
  }
}

// --- VAVT-40: STATEFUL CARD FOR DELETE CONFIRMATION ---
class _MyItemCard extends StatefulWidget {
  final dynamic item;
  final VoidCallback onDeleteConfirm;
  final VoidCallback onUpdateTap;
  const _MyItemCard({required this.item, required this.onDeleteConfirm, required this.onUpdateTap});
  @override State<_MyItemCard> createState() => _MyItemCardState();
}

class _MyItemCardState extends State<_MyItemCard> {
  bool _showConfirm = false; // Toggles the Figma delete confirmation box

  @override
  Widget build(BuildContext context) {
    String? imgPath = widget.item['image']; 
    bool hasImage = imgPath != null && imgPath.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Figma Left Side: Blue Bordered Image
              Container(
                width: 120, height: 140,
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF1A0088), width: 3),
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
              ),
              const SizedBox(width: 15),
              // Figma Right Side: Gray Details Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[300], borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item['owner'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 13)),
                      Text(widget.item['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(widget.item['dept'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(widget.item['status'], style: const TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          _figmaCardBtn("Delete", Colors.yellow, () => setState(() => _showConfirm = !_showConfirm)),
                          const SizedBox(width: 10),
                          _figmaCardBtn("Update", Colors.yellow, widget.onUpdateTap),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // --- Figma Confirmation Overlay (Drops down below the card) ---
        if (_showConfirm)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[400]!),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                const Text("Are you sure you want to delete?", style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _figmaCardBtn("Yes", Colors.yellow, widget.onDeleteConfirm),
                    const SizedBox(width: 20),
                    _figmaCardBtn("No", Colors.yellow, () => setState(() => _showConfirm = false)),
                  ],
                )
              ],
            ),
          )
      ],
    );
  }

  Widget _figmaCardBtn(String t, Color c, Function() action) => GestureDetector(
    onTap: action,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), 
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black87, width: 1)), 
      child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black))
    )
  );
}

// ==================== EDIT ITEM SCREEN (VAVT-40 "Full Info" Overlay) ====================
class EditItemScreen extends StatefulWidget {
  final dynamic item;
  const EditItemScreen({super.key, required this.item});
  @override State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late TextEditingController _titleCtrl; late TextEditingController _descCtrl;
  String? _selectedCondition; String? _selectedStatus; String? _selectedDept;
  String? _itemPhotoPath; bool _isUpdating = false;

  final List<String> _lnuDepartments = [
    'Bachelor of Elementary Education', 'Bachelor of Early Childhood Education', 'Bachelor of Special Needs Education', 'Bachelor of Technology and Livelihood Education', 'Bachelor of Physical Education', 'Bachelor of Secondary Education major in English', 'Bachelor of Secondary Education major in Filipino', 'Bachelor of Secondary Education major in Mathematics', 'Bachelor of Secondary Education major in Science', 'Bachelor of Secondary Education major in Social Studies', 'Bachelor of Secondary Education major in Values Education', 'Teacher Certificate Program (TCP)', 'Bachelor of Library and Information Science', 'Bachelor of Arts in Communication', 'Bachelor of Music in Music Education', 'Bachelor of Science in Information Technology', 'Bachelor of Arts in English Language', 'Bachelor of Arts in Political Science', 'Bachelor of Science in Biology', 'Bachelor of Science in Social Work', 'Bachelor of Science in Tourism Management', 'Bachelor of Science in Hospitality Management', 'Bachelor of Science in Entrepreneurship', 'Faculty / Staff'
  ];
  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];
  final List<String> _statuses = ['Available', 'Borrowed', 'Lost'];

  @override void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item['title']);
    _descCtrl = TextEditingController(text: widget.item['description']);
    _selectedCondition = widget.item['condition'];
    _selectedStatus = widget.item['status'];
    _selectedDept = widget.item['dept'];
    _itemPhotoPath = widget.item['image'];
    if (_itemPhotoPath != null && _itemPhotoPath!.isEmpty) _itemPhotoPath = null;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _itemPhotoPath = image.path);
  }

  Future<void> _updateItem() async {
    setState(() => _isUpdating = true);
    try {
      await http.put(Uri.parse('http://10.0.2.2:5000/api/items/${widget.item['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleCtrl.text, 'description': _descCtrl.text, 'condition': _selectedCondition, 
          'status': _selectedStatus, 'department': _selectedDept, 'item_image_path': _itemPhotoPath ?? ""
        }));
      Navigator.pop(context);
    } finally { setState(() => _isUpdating = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0088),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), // Clean top
      body: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black)),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Back Button (Yellow Circle)
                Align(alignment: Alignment.topLeft, child: GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black)))),
                const SizedBox(height: 10),
                
                // Editable Image
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 140, height: 160,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF1A0088), width: 3), image: _itemPhotoPath != null ? DecorationImage(image: FileImage(File(_itemPhotoPath!)), fit: BoxFit.cover) : null),
                    child: _itemPhotoPath == null ? const Icon(Icons.camera_alt, color: Color(0xFF1A0088), size: 40) : null,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Read-Only Owner
                _infoLabel("Owner"), Text(widget.item['owner'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 15),
                
                // Editable Fields
                _infoLabel("Item Name"), _editInput(_titleCtrl),
                _infoLabel("Department"), _editDropdown(_selectedDept, _lnuDepartments, (v) => setState(() => _selectedDept = v)),
                _infoLabel("Description"), _editInput(_descCtrl, maxLines: 3),
                _infoLabel("Condition"), _editDropdown(_selectedCondition, _conditions, (v) => setState(() => _selectedCondition = v)),
                _infoLabel("Status"), _editDropdown(_selectedStatus, _statuses, (v) => setState(() => _selectedStatus = v)),
                
                const SizedBox(height: 30),
                _isUpdating ? const CircularProgressIndicator() : ElevatedButton(
                  onPressed: _updateItem, 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: const Size(140, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.black))), 
                  child: const Text("Update", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 5, top: 10), child: Text(t, style: const TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 14)));
  Widget _editInput(TextEditingController ctrl, {int maxLines = 1}) => TextField(controller: ctrl, maxLines: maxLines, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), decoration: InputDecoration(filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)));
  Widget _editDropdown(String? val, List<String> items, Function(String?) onChanged) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: val, isExpanded: true, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14), items: items.map((c) => DropdownMenuItem(value: c, child: Text(c, textAlign: TextAlign.center))).toList(), onChanged: onChanged)));
}

// Global Mini Button Helper
Widget _miniBtn(String t, Color c, Function() action) => GestureDetector(
  onTap: action,
  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)), child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))
);

// ==================== ADD ITEM SCREEN ====================
class AddItemScreen extends StatefulWidget { const AddItemScreen({super.key}); @override State<AddItemScreen> createState() => _AddItemScreenState(); }
class _AddItemScreenState extends State<AddItemScreen> {
  final _titleCtrl = TextEditingController(); final _descCtrl = TextEditingController(); final _qtyCtrl = TextEditingController(text: "1"); 
  String? _selectedCondition; String? _itemPhotoPath; bool _isPosting = false;
  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];

  Future<void> _pickItemImage() async { final image = await ImagePicker().pickImage(source: ImageSource.gallery); if (image != null) setState(() => _itemPhotoPath = image.path); }
  Future<void> _postItem() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty || _selectedCondition == null) return;
    setState(() => _isPosting = true);
    try {
      final res = await http.post(Uri.parse('http://10.0.2.2:5000/api/items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ 'title': _titleCtrl.text, 'description': _descCtrl.text, 'quantity': _qtyCtrl.text.isEmpty ? "1" : _qtyCtrl.text, 'condition': _selectedCondition, 'item_image_path': _itemPhotoPath ?? "", 'owner_name': currentUser!['full_name'], 'department': currentUser!['department'], 'user_id': currentUser!['id'] }));
      if (res.statusCode == 201) Navigator.pop(context); 
    } finally { setState(() => _isPosting = false); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFF1A0088), appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.yellow), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context))), body: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 30), child: Column(children: [const Text("Huramay", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 20), GestureDetector(onTap: _pickItemImage, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), image: _itemPhotoPath != null ? DecorationImage(image: FileImage(File(_itemPhotoPath!)), fit: BoxFit.cover) : null), child: _itemPhotoPath == null ? const Icon(Icons.camera_alt, color: Color(0xFF1A0088), size: 60) : null)), const SizedBox(height: 10), ElevatedButton(onPressed: _pickItemImage, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black), child: const Text("Add Image", style: TextStyle(fontWeight: FontWeight.bold))), const SizedBox(height: 30), _addItemLabel("Item Name"), _addItemInput(_titleCtrl, "e.g., IT 101 Textbook"), _addItemLabel("Description"), _addItemInput(_descCtrl, "Details about the item...", maxLines: 3), Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_addItemLabel("Quantity"), _addItemInput(_qtyCtrl, "1", isNumber: true)])), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_addItemLabel("Condition"), Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedCondition, hint: const Text("Select"), isExpanded: true, items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _selectedCondition = v))))])),]), const SizedBox(height: 50), _isPosting ? const CircularProgressIndicator(color: Colors.yellow) : ElevatedButton(onPressed: _postItem, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text("POST ITEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), const SizedBox(height: 30)])));
  }
  Widget _addItemLabel(String t) => Padding(padding: const EdgeInsets.only(left: 10, bottom: 5, top: 15), child: Text(t, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 14))); Widget _addItemInput(TextEditingController ctrl, String hint, {int maxLines = 1, bool isNumber = false}) => TextField(controller: ctrl, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text, inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [], style: const TextStyle(color: Colors.black), decoration: InputDecoration(filled: true, fillColor: Colors.white, hintText: hint, hintStyle: const TextStyle(color: Colors.grey), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)));
}

// ==================== AUTH & PROFILE SCREENS ====================
// (LoginScreen, SignUpScreen, ProfileScreen, and PasswordResetScreen remain exactly as they were in your code to save space here, but do not delete them from your file!)
class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState() => _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(); final _passCtrl = TextEditingController();
  Future<void> doLogin() async {
    try {
      var res = await http.post(Uri.parse('http://10.0.2.2:5000/api/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': _emailCtrl.text, 'password': _passCtrl.text}));
      var data = jsonDecode(res.body); 
      if (res.statusCode == 200) { currentUser = data; Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const DashboardScreen())); } 
      else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']))); }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error"))); }
  }
  @override Widget build(BuildContext context) { return Scaffold(body: Container(width: double.infinity, height: double.infinity, decoration: _figmaBackground(), child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Huramay", style: TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 40), const Text("Login", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 30), _figmaLabel("Email"), _figmaInputAuth(_emailCtrl), _figmaLabel("Password"), _figmaInputAuth(_passCtrl, isPass: true), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Don't have an account? ", style: TextStyle(color: Colors.white)), GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpScreen())), child: const Text("SignUp", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)))]), const SizedBox(height: 40), _figmaButton("Login", doLogin)])))); }
}

class SignUpScreen extends StatefulWidget { const SignUpScreen({super.key}); @override State<SignUpScreen> createState() => _SignUpScreenState(); }
class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController(); final _emailCtrl = TextEditingController(); final _passCtrl = TextEditingController(); final _confCtrl = TextEditingController(); String? _selectedDept; 
  final List<String> _lnuDepartments = ['Bachelor of Science in Information Technology', 'Faculty / Staff']; // Add rest of array back here
  Future<void> doSignup() async {
    if (_selectedDept == null || _passCtrl.text != _confCtrl.text) return;
    try { var res = await http.post(Uri.parse('http://10.0.2.2:5000/api/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'full_name': _nameCtrl.text, 'email': _emailCtrl.text, 'department': _selectedDept, 'password': _passCtrl.text})); if (res.statusCode == 201) Navigator.pop(context); } catch (e) {}
  }
  @override Widget build(BuildContext context) { return Scaffold(body: Container(width: double.infinity, height: double.infinity, decoration: _figmaBackground(), child: SingleChildScrollView(padding: const EdgeInsets.all(40), child: Column(children: [const SizedBox(height: 60), const Text("Huramay", style: TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text("SignUp", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 30), _figmaLabel("Full Name"), _figmaInputAuth(_nameCtrl), _figmaLabel("Email"), _figmaInputAuth(_emailCtrl), _figmaLabel("Department"), Container(decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 15), child: DropdownButtonHideUnderline(child: DropdownButtonFormField<String>(isExpanded: true, value: _selectedDept, hint: const Text("Select program", style: TextStyle(fontSize: 12)), items: _lnuDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) => setState(() => _selectedDept = v), decoration: const InputDecoration(border: InputBorder.none)))), _passInputWithLabel("Password", _passCtrl), _passInputWithLabel("Confirm Password", _confCtrl), const SizedBox(height: 40), _figmaButton("SignUp", doSignup)])))); }
  Widget _passInputWithLabel(String label, TextEditingController ctrl) { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_figmaLabel(label), _figmaInputAuth(ctrl, isPass: true)]); }
}

class ProfileScreen extends StatefulWidget { const ProfileScreen({super.key}); @override State<ProfileScreen> createState() => _ProfileScreenState(); }
class _ProfileScreenState extends State<ProfileScreen> {
  String? _localPhotoPath;
  @override void initState() { super.initState(); _localPhotoPath = currentUser?['photo_path']; if (_localPhotoPath != null && _localPhotoPath!.isEmpty) _localPhotoPath = null; }
  Future<void> _pickImage() async { final image = await ImagePicker().pickImage(source: ImageSource.gallery); if (image != null) setState(() => _localPhotoPath = image.path); }
  Future<void> _saveProfile() async { try { var res = await http.post(Uri.parse('http://10.0.2.2:5000/api/user/update'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'id': currentUser!['id'], 'photo_path': _localPhotoPath ?? ""})); if (res.statusCode == 200) { currentUser!['photo_path'] = _localPhotoPath; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Saved!"))); } } catch (e) {} }
  void _logout() { currentUser = null; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (route) => false); }
  @override Widget build(BuildContext context) {
    double rating = (currentUser?['rating'] ?? 0.0).toDouble(); List<Widget> stars = List.generate(5, (index) => Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.yellow, size: 30));
    return Scaffold(backgroundColor: const Color(0xFF1A0088), appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context))))), body: SingleChildScrollView(child: SizedBox(width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [const Text("Huramay", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 20), CircleAvatar(radius: 50, backgroundColor: Colors.white, backgroundImage: _localPhotoPath != null ? FileImage(File(_localPhotoPath!)) : null, child: _localPhotoPath == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null), const SizedBox(height: 10), ElevatedButton(onPressed: _pickImage, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black), child: const Text("Photo Upload", style: TextStyle(fontWeight: FontWeight.bold))), const SizedBox(height: 30), _profileField("Name", currentUser?['full_name'] ?? "Unknown"), _profileField("Email", currentUser?['email'] ?? "Unknown"), _profileField("Department", currentUser?['department'] ?? "Unknown"), const SizedBox(height: 20), const Text("Rating", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)), Row(mainAxisAlignment: MainAxisAlignment.center, children: stars), const SizedBox(height: 30), TextButton(onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (c) => const PasswordResetScreen())); }, child: const Text("Password Reset", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16))), const SizedBox(height: 20), ElevatedButton(onPressed: _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: const Size(120, 45)), child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold))), const SizedBox(height: 15), ElevatedButton(onPressed: _logout, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: const Size(120, 45)), child: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold))), const SizedBox(height: 40)]))));
  }
  Widget _profileField(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(children: [Text(label, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)), Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))]));
}

class PasswordResetScreen extends StatefulWidget { const PasswordResetScreen({super.key}); @override State<PasswordResetScreen> createState() => _PasswordResetScreenState(); }
class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailCtrl = TextEditingController(); final _passCtrl = TextEditingController(); final _confCtrl = TextEditingController();
  Future<void> doReset() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || _passCtrl.text != _confCtrl.text) return;
    try { var res = await http.post(Uri.parse('http://10.0.2.2:5000/api/user/reset_password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': _emailCtrl.text, 'new_password': _passCtrl.text, 'current_user_id': currentUser!['id']})); if (res.statusCode == 200) Navigator.pop(context); } catch (e) {}
  }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFF1A0088), appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context))))), body: SingleChildScrollView(padding: const EdgeInsets.all(40), child: Column(children: [const Text("Huramay", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 50), _whiteResetLabel("Email"), _yellowResetInput(_emailCtrl), _whiteResetLabel("Password"), _yellowResetInput(_passCtrl, isPass: true), _whiteResetLabel("Confirm Password"), _yellowResetInput(_confCtrl, isPass: true), const SizedBox(height: 50), ElevatedButton(onPressed: doReset, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: const Size(120, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text("Reset", style: TextStyle(fontWeight: FontWeight.bold)))]))); }
  Widget _whiteResetLabel(String text) => Padding(padding: const EdgeInsets.only(left: 10, bottom: 5, top: 15), child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)))); Widget _yellowResetInput(TextEditingController ctrl, {bool isPass = false}) => TextField(controller: ctrl, obscureText: isPass, style: const TextStyle(color: Colors.black), decoration: InputDecoration(filled: true, fillColor: Colors.yellow, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none)));
}

// Global UI Helpers
BoxDecoration _figmaBackground() => const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A0088), Color(0xFFFDEB00)], begin: Alignment.topCenter, end: Alignment.bottomCenter));
Widget _figmaLabel(String text) => Padding(padding: const EdgeInsets.only(left: 10, bottom: 5, top: 15), child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))));
Widget _figmaInputAuth(TextEditingController ctrl, {bool isPass = false}) => TextField(controller: ctrl, obscureText: isPass, decoration: InputDecoration(filled: true, fillColor: Colors.grey[300], contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)));
Widget _figmaButton(String text, Function() action) => ElevatedButton(onPressed: action, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87, minimumSize: const Size(120, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 5), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));