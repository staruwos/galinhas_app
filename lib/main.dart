import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://xwpltrurqbbcmwnfuzqz.supabase.co', // Replace with your Supabase project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3cGx0cnVycWJiY213bmZ1enF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5NzA5MDIsImV4cCI6MjA2ODU0NjkwMn0.wGQSbdvqUVe4E8UfPcHnmCAWaPVpuBDiuf6lGRFlo70', // Replace with your anon public key
  );
  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chicken Tracker',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final _eggsController = TextEditingController();
  final _feedController = TextEditingController();
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final response = await supabase
        .from('chicken_logs')
        .select()
        .order('log_date', ascending: false);
    setState(() {
      _history = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      final eggs = int.tryParse(_eggsController.text) ?? 0;
      final feed = double.tryParse(_feedController.text) ?? 0.0;
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      await supabase.from('chicken_logs').upsert({
        'log_date': formattedDate,
        'egg_count': eggs,
        'feed_kg': feed,
      });

      _eggsController.clear();
      _feedController.clear();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chicken Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  ListTile(
                    title: Text("Data: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}"),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                  ),
                  TextFormField(
                    controller: _eggsController,
                    decoration: InputDecoration(labelText: 'Ovos produzidos'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: _feedController,
                    decoration: InputDecoration(labelText: 'Ração (kg)'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => value!.isEmpty ? 'Requerido' : null,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _submitData,
                    child: Text('Gravar'),
                  ),
                ],
              ),
            ),
            Divider(height: 40),
            Text('Histórico', style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return ListTile(
                    title: Text('${item['log_date']}'),
                    subtitle: Text('Ovos: ${item['egg_count']}, Ração: ${item['feed_kg']}kg'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
