import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

String formatarData(String dataOriginal) {
  try {
    DateTime dataUtc = HttpDate.parse(dataOriginal);
    DateTime dataLocal = dataUtc.toLocal();
    final formato = DateFormat('dd/MM/yyyy');
    return formato.format(dataLocal);
  } catch (e) {
    return dataOriginal;
  }
}

var dataFormatter = MaskTextInputFormatter(
  mask: '##/##/####',
  filter: {"#": RegExp(r'[0-9]')},
  type: MaskAutoCompletionType.lazy,
);

var mobileFormatter = MaskTextInputFormatter(
  mask: '+## (##) #####-####',
  filter: {"#": RegExp(r'[0-9]')},
  type: MaskAutoCompletionType.lazy,
);

const String ips = "localhost:5000";

int? idVeterinario;

String? nomeVeterinario;

void main() {
  runApp(MaterialApp(home: TelaInicial()));
}

class TelaInicial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    return Scaffold(
      backgroundColor: const Color(0xFF21C5C1),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(height: 15 * heightFactor),
            Center(
              child: Image.asset(
                'image/dermapetbottomless.png',
                width: 400 * widthFactor,
                height: 400 * heightFactor,
                fit: BoxFit.cover,
              ),
            ),
            // Botão
            Padding(
              padding: EdgeInsets.only(bottom: 30.0 * heightFactor),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF49D5D2),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: 60 * widthFactor,
                    vertical: 20 * heightFactor,
                  ),
                  textStyle: TextStyle(fontSize: 23 * widthFactor),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                },
                child: const Text("Iniciar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Ids {
  int userid;
  Ids({required this.userid});
}

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  List<Ids> validarr = [];
  TextEditingController userController = TextEditingController();
  TextEditingController senhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarIds();
  }

  void carregarIds() async {
    try {
      final Ids = await reqValidar();
      setState(() {
        validarr = Ids;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<List<Ids>> reqValidar() async {
    final url = Uri.parse("http://$ips/verifyuser");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": userController.text,
        "senha": senhaController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Conexão feita')));
      final data = jsonDecode(response.body);
      if (data['usuarioId'] != null) {
        final usuario = Ids(userid: data['usuarioId']['id']);
        return [usuario];
      } else {
        return [];
      }
    } else {
      throw Exception("Erro ao carregar usuarios: ${response.body}");
    }
  }

  //conexão backend
  Future<String?> verificaruser() async {
    final url = Uri.parse("http://$ips/verifyuser");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "email": userController.text,
          "senha": senhaController.text,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('id') && data['id'] != null) {
          idVeterinario = data['id'];
          nomeVeterinario = userController.text;
          debugPrint("Id do Veterinário=$idVeterinario");
          return null;
        } else {
          return "Veterinário não identificado no servidor";
        }
      } else {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['mensagem'] ?? "Usuário ou senha inválidos";
      }
    } catch (e) {
      debugPrint("Erro na verificação: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      return "Erro de conexão com o servidor: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    return Scaffold(
      //background
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('image/backgrounddp.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          //foreground
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 600.0 * heightFactor,
                  width: 340.0 * widthFactor,
                  color: Colors.white,
                  child: Column(
                    children: [
                      //logo
                      Padding(
                        padding: EdgeInsets.only(top: 10.0 * heightFactor),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60 * widthFactor),
                          child: CircleAvatar(
                            radius: 50 * widthFactor,
                            backgroundImage: AssetImage('image/dermapet.jpeg'),
                          ),
                        ),
                      ),
                      SizedBox(height: 80 * heightFactor),
                      //Textfield User
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40 * widthFactor),
                        child: (Container(
                          height: 40 * heightFactor,
                          width: 200 * widthFactor,
                          color: Colors.grey[300],
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 12 * widthFactor),
                          child: TextField(
                            controller: userController,
                            decoration: InputDecoration(
                              hintText: 'Usuário',
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: TextStyle(fontSize: 20 * widthFactor),
                          ),
                        )),
                      ),
                      SizedBox(height: 20 * heightFactor),
                      //Textfield password
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40 * widthFactor),
                        child: (Container(
                          height: 40 * heightFactor,
                          width: 200 * widthFactor,
                          color: Colors.grey[300],
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 12 * widthFactor),
                          child: TextField(
                            controller: senhaController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Senha',
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: TextStyle(fontSize: 20 * widthFactor),
                          ),
                        )),
                      ),
                      SizedBox(height: 40 * heightFactor),
                      //botao
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.0 * heightFactor),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF49D5D2),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 40 * widthFactor,
                              vertical: 10 * heightFactor,
                            ),
                            textStyle: TextStyle(fontSize: 18 * widthFactor),
                          ),
                          onPressed: () async {
                            if (userController.text.isEmpty ||
                                senhaController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Preencha os campos corretamente',
                                  ),
                                ),
                              );
                              return;
                            }
                            String? erro = await verificaruser();
                            if (erro != null) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(erro)));
                              return;
                            } else {
                              userController.clear();
                              senhaController.clear();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrimeiraTela(),
                                  settings: RouteSettings(name: 'PrimeiraTela'),
                                ),
                              );
                            }
                          },
                          child: Text("Login"),
                        ),
                      ),
                      SizedBox(height: 20 * heightFactor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 60 * widthFactor,
                            child: Divider(color: Colors.black, thickness: 1),
                          ),
                          SizedBox(width: 10 * widthFactor),
                          Text(
                            'OU',
                            style: TextStyle(fontSize: 16 * widthFactor),
                          ),
                          SizedBox(width: 10 * widthFactor),
                          SizedBox(
                            width: 60 * widthFactor,
                            child: Divider(color: Colors.black, thickness: 1),
                          ),
                        ],
                      ),
                      SizedBox(height: 20 * heightFactor),
                      GestureDetector(
                        onTap: () {
                          userController.clear();
                          senhaController.clear();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Signup()),
                          );
                        },
                        child: Text(
                          'Criar Conta',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 16 * widthFactor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Cadastro {
  String phone;
  String email;
  String usuario;
  String senha;
  String confirm;
  Cadastro({
    required this.phone,
    required this.email,
    required this.usuario,
    required this.senha,
    required this.confirm,
  });
}

class Signup extends StatefulWidget {
  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController usuarioController = TextEditingController();
  TextEditingController senhaController = TextEditingController();
  TextEditingController confirmController = TextEditingController();

  //conexão backend
  Future<String?> cadastrarUsuario() async {
    final url = Uri.parse("http://$ips/adduser");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nome": usuarioController.text,
        "senha": senhaController.text,
        "email": emailController.text,
      }),
    );

    debugPrint(usuarioController.text);
    debugPrint(senhaController.text);
    debugPrint(emailController.text);

    if (response.statusCode == 200) {
      return null;
    } else {
      try {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final mensagem = data['mensagem'] ?? 'Erro desconhecido ao cadastrar';
        debugPrint("Erro ao cadastrar: $mensagem");
        return mensagem;
      } catch (e) {
        debugPrint("Erro ao decodificar resposta: $e");
        return "Erro inesperado ao cadastrar";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    return Scaffold(
      //background
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('image/backgrounddp.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          //foreground
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 650.0 * heightFactor,
                  width: 340.0 * widthFactor,
                  color: Colors.white,
                  child: Column(
                    children: [
                      //logo
                      Padding(
                        padding: EdgeInsets.only(top: 15.0 * heightFactor),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60 * widthFactor),
                          child: CircleAvatar(
                            radius: 50 * widthFactor,
                            backgroundImage: AssetImage('image/dermapet.jpeg'),
                          ),
                        ),
                      ),
                      SizedBox(height: 80 * heightFactor),
                      //Textfield mobile number
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40 * widthFactor),
                        child: Container(
                          height: 40 * heightFactor,
                          width: 220 * widthFactor,
                          color: Colors.grey[300],
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 12 * widthFactor),
                          child: TextField(
                            controller: phoneController,
                            inputFormatters: [mobileFormatter],
                            decoration: InputDecoration(
                              hintText: 'Número de telefone',
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: TextStyle(fontSize: 20 * widthFactor),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * heightFactor),
                      //Textfield email
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40 * widthFactor),
                        child: (Container(
                          height: 40 * heightFactor,
                          width: 220 * widthFactor,
                          color: Colors.grey[300],
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 12 * widthFactor),
                          child: TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: TextStyle(fontSize: 20 * widthFactor),
                          ),
                        )),
                      ),
                      SizedBox(height: 20 * heightFactor),
                      //Textfield user
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40 * widthFactor),
                        child: (Container(
                          height: 40 * heightFactor,
                          width: 220 * widthFactor,
                          color: Colors.grey[300],
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 12 * widthFactor),
                          child: TextField(
                            controller: usuarioController,
                            decoration: InputDecoration(
                              hintText: 'Usuário',
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: TextStyle(fontSize: 20 * widthFactor),
                          ),
                        )),
                      ),
                      SizedBox(height: 20 * heightFactor),
                      //Textfield Password
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40 * widthFactor),
                        child: (Container(
                          height: 40 * heightFactor,
                          width: 220 * widthFactor,
                          color: Colors.grey[300],
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 12 * widthFactor),
                          child: TextField(
                            controller: senhaController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Senha',
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: TextStyle(fontSize: 20 * widthFactor),
                          ),
                        )),
                      ),
                      SizedBox(height: 20 * heightFactor),
                      //Textfield Confirm password
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40 * widthFactor),
                        child: (Container(
                          height: 40 * heightFactor,
                          width: 220 * widthFactor,
                          color: Colors.grey[300],
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 12 * widthFactor),
                          child: TextField(
                            controller: confirmController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Confirme a senha',
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: TextStyle(fontSize: 20 * widthFactor),
                          ),
                        )),
                      ),
                      SizedBox(height: 40 * heightFactor),
                      //botao
                      Padding(
                        padding: EdgeInsets.all(10.0 * widthFactor),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF49D5D2),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 40 * widthFactor,
                              vertical: 10 * heightFactor,
                            ),
                            textStyle: TextStyle(fontSize: 18 * widthFactor),
                          ),
                          onPressed: () async {
                            if (senhaController.text !=
                                confirmController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Senhas não coincidem')),
                              );
                              return;
                            } else if (phoneController.text.isEmpty ||
                                emailController.text.isEmpty ||
                                usuarioController.text.isEmpty ||
                                senhaController.text.isEmpty ||
                                confirmController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Preencha todos os campos'),
                                ),
                              );
                              return;
                            }
                            String? erro = await cadastrarUsuario();
                            if (erro != null) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(erro)));
                              return;
                            } else {
                              phoneController.clear();
                              emailController.clear();
                              usuarioController.clear();
                              senhaController.clear();
                              confirmController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cadastrado com sucesso!'),
                                ),
                              );

                              Navigator.pop(context);
                            }
                          },
                          child: Text("Confirmar"),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Login()),
                          );
                        },
                        child: Text(
                          'voltar',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 16 * widthFactor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Laudo {
  String animal;
  String sexo;
  String dono;
  String alimentos;
  String email;
  String telefone;
  String endereco;
  double peso;
  String data;
  int id;
  int usuarioid;
  int clienteid;
  String? observacao;
  String? fotoPath;
  String racoes;

  Laudo({
    required this.animal,
    required this.sexo,
    required this.dono,
    required this.alimentos,
    required this.email,
    required this.telefone,
    required this.endereco,
    required this.peso,
    required this.data,
    required this.id,
    required this.usuarioid,
    required this.clienteid,
    required this.observacao,
    required this.fotoPath,
    required this.racoes,
  });

  factory Laudo.fromJson(Map<String, dynamic> json, {Clientes? cliente}) {
    return Laudo(
      id: json['id'] ?? 0,
      clienteid: json['cliente_id'] ?? 0,
      usuarioid: cliente?.usuarioid ?? 0,
      dono: cliente?.nome ?? 'Desconhecido',
      animal: cliente?.nomeAnimal ?? 'Não informado',
      sexo: json['sexo'] ?? 'Não informado',
      peso: (json['peso'] is num) ? (json['peso'] as num).toDouble() : 0.0,
      data: json['data'] ?? '',
      alimentos: json['alimentos'] ?? '',
      telefone: cliente?.telefone ?? 'Não informado',
      email: cliente?.email ?? 'Não informado',
      endereco: cliente?.endereco ?? 'Não informado',
      fotoPath: json['fotoPath'] ?? '',
      observacao: json['observacao'] ?? '',
      racoes: json['racoes'] ?? '',
    );
  }
}

class PrimeiraTela extends StatefulWidget {
  @override
  _PrimeiraTelaState createState() => _PrimeiraTelaState();
}

class _PrimeiraTelaState extends State<PrimeiraTela> {
  List<Laudo> cards = [];
  List<Clientes> cadastro = [];
  bool _carregando = true;
  bool _erro = false;
  bool _snackbar = false;

  @override
  void initState() {
    super.initState();
    carregarLaudos();
  }

  Future<void> carregarLaudos() async {
    setState(() {
      _erro = false;
      _carregando = true;
      _snackbar = false;
    });
    try {
      final clientes = await reqClientes();
      List<Laudo> todosLaudos = [];

      for (var cliente in clientes) {
        final exames = await reqExames(cliente.id);
        final examesCompletos = exames.map((e) {
          return Laudo(
            id: e.id,
            clienteid: e.clienteid,
            usuarioid: e.usuarioid,
            animal: cliente.nomeAnimal.isNotEmpty
                ? cliente.nomeAnimal
                : "Não informado",
            dono: cliente.nome.isNotEmpty ? cliente.nome : "Desconhecido",
            sexo: e.sexo.isNotEmpty ? e.sexo : "Não informado",
            peso: e.peso,
            data: e.data,
            alimentos: e.alimentos,
            telefone: cliente.telefone.isNotEmpty
                ? cliente.telefone
                : "Não informado",
            email: cliente.email.isNotEmpty ? cliente.email : "Não informado",
            endereco: cliente.endereco.isNotEmpty
                ? cliente.endereco
                : "Não informado",
            fotoPath: e.fotoPath,
            observacao: e.observacao,
            racoes: e.racoes,
          );
        }).toList();
        todosLaudos.addAll(examesCompletos);
      }

      setState(() {
        cards = todosLaudos;
      });
      if (todosLaudos.isEmpty && !_snackbar && mounted) {
        _snackbar = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Nenhum laudo encontrado. Cadastre um novo."),
            backgroundColor: Colors.orange[800],
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao carregar laudos: $e");
      setState(() {
        _erro = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao carregar os laudos. Verifique a conexão com a internet.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<List<Clientes>> reqClientes() async {
    final url = Uri.parse("http://$ips/verifyclientes");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuarioId": idVeterinario}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> lista = data["clientes"] ?? [];
      return lista
          .map(
            (json) => Clientes(
              id: json['id'],
              usuarioid: json['usuario_id'],
              nome: json['nome'] ?? "",
              nomeAnimal: json['nome_animal'] ?? "",
              telefone: json['telefone'] ?? "",
              email: json['email'] ?? "",
              endereco: json['endereco'] ?? "",
            ),
          )
          .toList();
    } else {
      throw Exception("Erro ao carregar clientes: ${response.body}");
    }
  }

  Future<List<Laudo>> reqExames(int clienteId) async {
    final url = Uri.parse("http://$ips/verifyexame");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"clienteId": clienteId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> lista = data["exames"] ?? [];
      return lista
          .map((json) => Laudo.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Erro ao carregar exames: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.black,
              size: 28 * widthFactor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Account()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final recarregar = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CadastroCliente(cards: cards, cadastro: cadastro),
            ),
          );
          if (recarregar == true) {
            await carregarLaudos();
          }
        },
        child: Icon(Icons.person),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('image/backgrounddp2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (_carregando)
            Center(child: CircularProgressIndicator())
          else if (_erro)
            Center(
              child: _carregando
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _carregando = true;
                        });
                        carregarLaudos();
                      },
                      child: Text("Tentar novamente"),
                    ),
            )
          else if (cards.isEmpty)
            Center(
              child: Text(
                "Nenhum laudo realizado.",
                style: TextStyle(fontSize: 16),
              ),
            )
          else
            ListView(
              children: [
                SizedBox(height: 100 * heightFactor),
                Column(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetalhesLaudo(laudo: cards[i]),
                              ),
                            );
                          },
                          child: Card(
                            child: SizedBox(
                              height: 130.0 * heightFactor,
                              width: 330.0 * widthFactor,
                              child: Padding(
                                padding: EdgeInsets.all(8.0 * widthFactor),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Exame: ${i + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16 * widthFactor,
                                            ),
                                          ),
                                          SizedBox(height: 15 * heightFactor),
                                          Text('Animal: ${cards[i].animal}'),
                                          Text('Dono: ${cards[i].dono}'),
                                          Text(
                                            'Data: ${formatarData(cards[i].data)}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10 * widthFactor),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              'image/dermapetbottomless.png',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * heightFactor),
                    ],
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class Clientes {
  String nome;
  String nomeAnimal;
  String telefone;
  String email;
  String endereco;
  int id;
  int usuarioid;

  Clientes({
    required this.nome,
    required this.nomeAnimal,
    required this.telefone,
    required this.email,
    required this.endereco,
    required this.id,
    required this.usuarioid,
  });
}

class CadastroCliente extends StatefulWidget {
  final List<Laudo> cards;
  final List<Clientes> cadastro;
  CadastroCliente({Key? key, required this.cards, required this.cadastro})
    : super(key: key);

  @override
  _CadastroClienteState createState() => _CadastroClienteState();
}

class _CadastroClienteState extends State<CadastroCliente> {
  List<Clientes> clientes = [];
  bool _carregando = true;
  bool _erro = false;
  bool _snackbar = false;

  @override
  void initState() {
    super.initState();
    carregarClientes();
  }

  void carregarClientes() async {
    setState(() {
      _erro = false;
      _carregando = true;
      _snackbar = false;
    });
    try {
      final novos = await reqClientes();
      setState(() {
        clientes = novos;
      });
      if (novos.isEmpty && !_snackbar && mounted) {
        _snackbar = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Nenhum cliente encontrado. Cadastre um novo."),
            backgroundColor: Colors.orange[800],
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _erro = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao carregar os clientes. Verifique a conexão com a internet.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<List<Clientes>> reqClientes() async {
    final url = Uri.parse("http://$ips/verifyclientes");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuarioId": idVeterinario}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> lista = data["clientes"] ?? [];

      return lista
          .map(
            (json) => Clientes(
              id: json['id'] ?? 0,
              usuarioid: json['usuario_id'],
              nome: json['nome'] ?? "",
              nomeAnimal: json['nome_animal'] ?? "",
              telefone: json['telefone'] ?? "",
              email: json['email'] ?? "",
              endereco: json['endereco'] ?? "",
            ),
          )
          .toList();
    } else {
      throw Exception("Erro ao carregar clientes: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Clientes'),
        backgroundColor: Colors.transparent,
        elevation: 0.1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24 * widthFactor),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final recarregar = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ClientesInfos(cards: widget.cards, cadastro: widget.cadastro),
            ),
          );

          if (recarregar == true) {
            carregarClientes();
          }
          Navigator.pop(context, true);
        },
        child: Icon(Icons.add, size: 24 * widthFactor),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('image/backgrounddp2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (_carregando)
            Center(child: CircularProgressIndicator())
          else if (_erro)
            Center(
              child: _carregando
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _carregando = true;
                        });
                        carregarClientes();
                      },
                      child: Text("Tentar novamente"),
                    ),
            )
          else if (clientes.isEmpty)
            Center(
              child: Text(
                "Nenhum cliente cadastrado.",
                style: TextStyle(fontSize: 16),
              ),
            )
          else
            ListView(
              children: [
                SizedBox(height: 70 * heightFactor),
                Column(
                  children: [
                    for (int i = 0; i < clientes.length; i++) ...[
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final laudosDoCliente = widget.cards
                                .where((l) => l.clienteid == clientes[i].id)
                                .toList();

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClienteDetalhes(
                                  cliente: clientes[i],
                                  laudos: laudosDoCliente,
                                  cadastro: widget.cadastro,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            child: SizedBox(
                              height: 130.0 * heightFactor,
                              width: 330.0 * widthFactor,
                              child: Padding(
                                padding: EdgeInsets.all(8.0 * widthFactor),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cliente: ${i + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16 * widthFactor,
                                            ),
                                          ),
                                          SizedBox(height: 15 * heightFactor),
                                          Text(
                                            'Animal: ${clientes[i].nomeAnimal}',
                                          ),
                                          Text('Dono: ${clientes[i].nome}'),
                                          Text(
                                            'Endereço: ${clientes[i].endereco}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10 * widthFactor),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              'image/dermapetbottomless.png',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * heightFactor),
                    ],
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ClientesInfos extends StatefulWidget {
  final List<Laudo> cards;
  final List<Clientes> cadastro;
  ClientesInfos({required this.cards, required this.cadastro, Key? key})
    : super(key: key);

  @override
  _ClientesInfosState createState() => _ClientesInfosState();
}

class _ClientesInfosState extends State<ClientesInfos> {
  //controllers de armazenamento textfield
  TextEditingController nomeController = TextEditingController();
  TextEditingController nomeAnimalController = TextEditingController();
  TextEditingController telefoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController enderecoController = TextEditingController();

  bool _salvando = false;

  //conexão backend
  Future<String> adicionarCliente() async {
    final url = Uri.parse("http://$ips/addclientes");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "usuarioid": idVeterinario,
        "nome": nomeController.text,
        "nomeanimal": nomeAnimalController.text,
        "telefone": telefoneController.text,
        "email": emailController.text,
        "endereco": enderecoController.text,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("Cliente cadastrado com sucesso!");
      final data = jsonDecode(response.body);
      return data['id'].toString();
    } else {
      final Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint("Erro ao cadastrar: ${data['mensagem']}");
      return data['mensagem'] ?? "Erro desconhecido ao cadastrar";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('image/backgrounddp.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30 * widthFactor),
                child: Container(
                  height: 530.0 * heightFactor,
                  width: 340.0 * widthFactor,
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(height: 40 * heightFactor),
                      Text(
                        'Cadastre um novo cliente',
                        style: TextStyle(fontSize: 26 * widthFactor),
                      ),
                      SizedBox(height: 70 * heightFactor),
                      //Textfields
                      _buildTextField(
                        nomeController,
                        'Nome do cliente',
                        widthFactor,
                        heightFactor,
                      ),
                      SizedBox(height: 12 * heightFactor),
                      _buildTextField(
                        nomeAnimalController,
                        'Nome do animal',
                        widthFactor,
                        heightFactor,
                      ),
                      SizedBox(height: 12 * heightFactor),
                      _buildTextField(
                        telefoneController,
                        'Telefone',
                        widthFactor,
                        heightFactor,
                        inputFormatters: [mobileFormatter],
                      ),
                      SizedBox(height: 12 * heightFactor),
                      _buildTextField(
                        emailController,
                        'Email',
                        widthFactor,
                        heightFactor,
                      ),
                      SizedBox(height: 12 * heightFactor),
                      _buildTextField(
                        enderecoController,
                        'Endereço',
                        widthFactor,
                        heightFactor,
                      ),
                      Spacer(),
                      //botão
                      Padding(
                        padding: EdgeInsets.all(10.0 * widthFactor),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF49D5D2),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 40 * widthFactor,
                              vertical: 10 * heightFactor,
                            ),
                            textStyle: TextStyle(fontSize: 18 * widthFactor),
                          ),
                          onPressed: _salvando
                              ? null
                              : () async {
                                  setState(() => _salvando = true);

                                  if (nomeController.text.isEmpty ||
                                      nomeAnimalController.text.isEmpty ||
                                      telefoneController.text.isEmpty ||
                                      emailController.text.isEmpty ||
                                      enderecoController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Preencha todos os campos',
                                        ),
                                      ),
                                    );
                                    setState(() => _salvando = false);
                                    return;
                                  }

                                  try {
                                    final clienteId = await adicionarCliente();
                                    debugPrint(
                                      "Cliente cadastrado com sucesso: $clienteId",
                                    );

                                    nomeController.clear();
                                    nomeAnimalController.clear();
                                    telefoneController.clear();
                                    emailController.clear();
                                    enderecoController.clear();

                                    Navigator.pop(context, true);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao cadastrar cliente: $e',
                                        ),
                                      ),
                                    );
                                  }

                                  setState(() => _salvando = false);
                                },
                          child: _salvando
                              ? CircularProgressIndicator()
                              : Text("Confirmar"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    double widthFactor,
    double heightFactor, {
    List<TextInputFormatter>? inputFormatters,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40 * widthFactor),
      child: Container(
        height: 40 * heightFactor,
        width: 310 * widthFactor,
        color: Colors.grey[300],
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 12 * widthFactor),
        child: TextField(
          controller: controller,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            isCollapsed: true,
          ),
          style: TextStyle(fontSize: 20 * widthFactor),
        ),
      ),
    );
  }
}

class PreencherInfos extends StatefulWidget {
  final List<Laudo> cards;
  final List<Clientes> cadastro;
  final List<String> fotos;
  final Clientes clienteSelecionado;
  PreencherInfos({
    required this.cards,
    required this.cadastro,
    required this.fotos,
    required this.clienteSelecionado,
    Key? key,
  }) : super(key: key);
  @override
  _PreencherInfosState createState() => _PreencherInfosState();
}

class _PreencherInfosState extends State<PreencherInfos> {
  //controllers de armazenamento textfield
  TextEditingController animalController = TextEditingController();
  TextEditingController donoController = TextEditingController();
  TextEditingController idadeController = TextEditingController();
  TextEditingController sexoController = TextEditingController();
  TextEditingController racaController = TextEditingController();
  TextEditingController pesoController = TextEditingController();
  TextEditingController dataController = TextEditingController();

  bool _salvando = false;

  //conexão backend
  Future<String> adicionarLaudo(
    List<Box> boxes,
    List<Recomendacoes> racoes,
  ) async {
    final url = Uri.parse("http://$ips/addexame");

    final clienteId = widget.clienteSelecionado.id;
    debugPrint("o id do cliente é: $clienteId");

    final double peso = double.tryParse(pesoController.text) ?? 0;
    debugPrint("o peso do animal é: $peso");

    final List<Map<String, dynamic>> boxesjson = boxes
        .map((box) => {"name": box.name, "veri": box.veri})
        .toList();

    final List<Map<String, dynamic>> racoesjson = racoes
        .map(
          (racoes) => {
            "nome": racoes.nome,
            "marca": racoes.marca,
            "mensagem": racoes.mensagem,
          },
        )
        .toList();

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "cliente_id": clienteId,
        "alimentos": boxesjson,
        "peso": peso,
        "sexo": sexoController.text,
        "racoes": racoesjson,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("Exame cadastrado com sucesso!");
      return "ok";
    } else {
      final Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint("Erro ao cadastrar: ${data['mensagem']}");
      throw Exception("Erro ao cadastrar: ${data['mensagem']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('image/backgrounddp.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          //foreground
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30 * widthFactor),
                child: Container(
                  height: 690.0 * heightFactor,
                  width: 350.0 * widthFactor,
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(height: 40 * heightFactor),
                      Text(
                        'Início de um novo teste',
                        style: TextStyle(fontSize: 30 * widthFactor),
                      ),
                      SizedBox(height: 15 * heightFactor),
                      Text(
                        'Preencha esse questionário sobre o animal para continuar',
                        style: TextStyle(fontSize: 14 * widthFactor),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 60 * heightFactor),

                      //Textfield data
                      campoTexto(
                        dataController,
                        "dd/mm/aaaa",
                        widthFactor,
                        heightFactor,
                        formatter: dataFormatter,
                      ),

                      SizedBox(height: 15 * heightFactor),
                      campoTexto(
                        animalController,
                        "Nome do animal",
                        widthFactor,
                        heightFactor,
                      ),
                      SizedBox(height: 15 * heightFactor),
                      campoTexto(
                        donoController,
                        "Dono do animal",
                        widthFactor,
                        heightFactor,
                      ),
                      SizedBox(height: 15 * heightFactor),
                      campoTexto(
                        idadeController,
                        "Idade do animal",
                        widthFactor,
                        heightFactor,
                        keyboardType: TextInputType.number,
                        formatter: FilteringTextInputFormatter.digitsOnly,
                      ),
                      SizedBox(height: 15 * heightFactor),
                      campoTexto(
                        sexoController,
                        "Sexo do animal",
                        widthFactor,
                        heightFactor,
                      ),
                      SizedBox(height: 15 * heightFactor),
                      campoTexto(
                        racaController,
                        "Raça do animal",
                        widthFactor,
                        heightFactor,
                      ),
                      SizedBox(height: 15 * heightFactor),
                      campoTexto(
                        pesoController,
                        "Peso do animal",
                        widthFactor,
                        heightFactor,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        formatter: FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ),
                      const Spacer(),
                      //botao
                      Padding(
                        padding: EdgeInsets.all(10.0 * widthFactor),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF49D5D2),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 40 * widthFactor,
                              vertical: 10 * heightFactor,
                            ),
                            textStyle: TextStyle(fontSize: 18 * widthFactor),
                          ),
                          onPressed: _salvando
                              ? null
                              : () async {
                                  setState(() => _salvando = true);

                                  if (animalController.text.isEmpty ||
                                      donoController.text.isEmpty ||
                                      idadeController.text.isEmpty ||
                                      sexoController.text.isEmpty ||
                                      racaController.text.isEmpty ||
                                      pesoController.text.isEmpty ||
                                      dataController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Preencha todos os campos',
                                        ),
                                      ),
                                    );
                                    setState(() => _salvando = false);
                                    return;
                                  } else if (int.tryParse(
                                            idadeController.text,
                                          ) ==
                                          0 ||
                                      double.tryParse(pesoController.text) ==
                                          0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Preencha os campos corretamente',
                                        ),
                                      ),
                                    );
                                    setState(() => _salvando = false);
                                    return;
                                  }

                                  final result =
                                      await Navigator.push<
                                        Map<String?, dynamic>
                                      >(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Foto(
                                            cards: [],
                                            cadastro: widget.cadastro,
                                            index: 0,
                                          ),
                                        ),
                                      );
                                  if (result != null) {
                                    result['boxes'] as List<Box>;
                                    result['racoes'] as List<Recomendacoes>;
                                  }

                                  if (result != null) {
                                    try {
                                      await adicionarLaudo(
                                        result['boxes'],
                                        result['racoes'],
                                      );
                                      animalController.clear();
                                      donoController.clear();
                                      idadeController.clear();
                                      sexoController.clear();
                                      racaController.clear();
                                      pesoController.clear();
                                      dataController.clear();
                                      Navigator.pop(context);
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Erro ao cadastrar exame: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }

                                  setState(() => _salvando = false);
                                },

                          child: _salvando
                              ? CircularProgressIndicator()
                              : Text("Confirmar"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget campoTexto(
    TextEditingController controller,
    String hint,
    double widthFactor,
    double heightFactor, {
    TextInputFormatter? formatter,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40 * widthFactor),
      child: Container(
        height: 40 * heightFactor,
        width: 330 * widthFactor,
        color: Colors.grey[300],
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 12 * widthFactor),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatter != null ? [formatter] : null,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            isCollapsed: true,
          ),
          style: TextStyle(fontSize: 20 * widthFactor),
        ),
      ),
    );
  }
}

class Box {
  final int? x1;
  final int? y1;
  final int? x2;
  final int? y2;
  final int? veri;
  String name;

  Box({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.veri,
    this.name = "Sem nome",
  });

  factory Box.fromJson(Map<String, dynamic> json) {
    return Box(
      x1: json["x1"],
      y1: json["y1"],
      x2: json["x2"],
      y2: json["y2"],
      veri: json["veri"],
      name: json["name"] ?? "Sem nome",
    );
  }

  Map<String, dynamic> toJson() {
    return {"x1": x1, "y1": y1, "x2": x2, "y2": y2, "veri": veri, "name": name};
  }
}

class Recomendacoes {
  String? nome;
  String? marca;
  String? mensagem;

  Recomendacoes({
    required this.nome,
    required this.marca,
    required this.mensagem,
  });

  factory Recomendacoes.fromJson(Map<String, dynamic> json) {
    return Recomendacoes(
      nome: json["nome"] ?? '',
      marca: json["marca"] ?? '',
      mensagem: json["mensagem"] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {"nome": nome, "marca": marca, "mensagem": mensagem};
  }
}

class Foto extends StatefulWidget {
  final List<Laudo> cards;
  final List<Clientes> cadastro;

  final int index;
  const Foto({
    required this.cards,
    required this.cadastro,
    required this.index,
    Key? key,
  }) : super(key: key);
  @override
  _FotoState createState() => _FotoState();
}

class _FotoState extends State<Foto> {
  List<Box> boxes = [];
  List<Recomendacoes> racoes = [];
  String? fotoPath;
  Uint8List? imageBytes;
  bool _confirm = false;
  bool _confirm2 = false;
  bool _carregando = false;

  void atualizarFoto() {
    setState(() {});
    _confirm = true;
    _confirm2 = true;
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> pegarDaGaleria() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.gallery);
    if (foto != null && mounted) {
      setState(() {
        fotoPath = foto.path;
        if (widget.cards.isNotEmpty && widget.index < widget.cards.length) {
          widget.cards[widget.index].fotoPath = foto.path;
        }
      });
    }
  }

  Future<void> reqRacoes() async {
    try {
      var postUrl = Uri.parse('http://$ips/recomendacao');
      var postResponse = await http.post(
        postUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"boxes": boxes}),
      );

      if (postResponse.statusCode == 200) {
        debugPrint("Resposta do servidor: ${postResponse.body}");
        var data = jsonDecode(postResponse.body);

        List<Map<String, dynamic>> racoesJson = List<Map<String, dynamic>>.from(
          data['racoes']['racoes'],
        );

        setState(() {
          racoes = racoesJson.map((b) => Recomendacoes.fromJson(b)).toList();
          _confirm = true;
          _confirm2 = true;
        });
      } else {
        debugPrint("Erro ao retornar rações: ${postResponse.statusCode}");
      }
    } catch (e) {
      debugPrint("Erro ao retornar recomendações: $e");
    }
  }

  Future<void> processarImagem() async {
    if (fotoPath == null) return;

    try {
      setState(() {
        _carregando = true;
      });

      final fileBytes = await File(fotoPath!).readAsBytes();
      String base64Image = base64Encode(fileBytes);

      var postUrl = Uri.parse('http://$ips/imageProces');
      var postResponse = await http.post(
        postUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"img": base64Image}),
      );

      if (postResponse.statusCode == 200) {
        debugPrint("Resposta do servidor: ${postResponse.body}");
        var data = jsonDecode(postResponse.body);

        String receivedBase64 = data['img'];
        List<dynamic> boxesJson = data['boxes'];

        setState(() {
          imageBytes = base64Decode(receivedBase64);
          boxes = boxesJson.map((b) => Box.fromJson(b)).toList();
          _confirm = true;
        });
      } else {
        debugPrint("Erro ao processar: ${postResponse.statusCode}");
      }
    } catch (e) {
      debugPrint("Erro ao processar: $e");
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  void _onBoxTap(int index) async {
    final controller = TextEditingController(text: boxes[index].name);

    String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nomear área"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Digite o nome"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Salvar"),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        boxes[index].name = newName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    final originalWidth = 640.0; // tamanho original que o YOLO usou
    final originalHeight = 640.0;
    final displayedWidth = 280 * widthFactor;
    final displayedHeight = 280 * heightFactor;
    final scaleX = displayedWidth / originalWidth;
    final scaleY = displayedHeight / originalHeight;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('image/backgrounddp.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30 * widthFactor),
                child: Container(
                  height: 690.0 * heightFactor,
                  width: 350.0 * widthFactor,
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(height: 50 * heightFactor),
                      ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (_) => Wrap(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.camera_alt),
                                  title: Text('Tirar foto'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final path = await Navigator.push<String?>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CapturaCamera(),
                                      ),
                                    );
                                    if (path != null && mounted) {
                                      setState(() {
                                        fotoPath = path;
                                        if (widget.cards.isNotEmpty &&
                                            widget.index <
                                                widget.cards.length) {
                                          widget.cards[widget.index].fotoPath =
                                              path;
                                        }
                                      });
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.photo_library),
                                  title: Text('Escolher da galeria'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await pegarDaGaleria();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 130 * heightFactor),
                      if (fotoPath != null)
                        Container(
                          width: 280 * widthFactor,
                          height: 280 * heightFactor,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              20 * widthFactor,
                            ),
                            border: Border.all(color: Colors.black),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _carregando
                              ? CircularProgressIndicator(
                                  color: Color(0xFF49D5D2),
                                )
                              : imageBytes != null
                              ? Stack(
                                  children: [
                                    Image.memory(
                                      imageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                    ...boxes.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      Box box = entry.value;

                                      return Positioned(
                                        left: box.x1! * scaleX,
                                        top: box.y1! * scaleY,
                                        child: GestureDetector(
                                          onTap: () => _onBoxTap(index),
                                          child: Container(
                                            width: (box.x2! - box.x1!) * scaleX,
                                            height:
                                                (box.y2! - box.y1!) * scaleY,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                              color: Colors.red.withValues(
                                                alpha: 0.1,
                                              ),
                                            ),
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: Text(
                                                box.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                  backgroundColor:
                                                      Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                )
                              : Image.file(File(fotoPath!), fit: BoxFit.cover),
                        )
                      else
                        Container(
                          width: 280 * widthFactor,
                          height: 280 * heightFactor,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              16 * widthFactor,
                            ),
                            border: Border.all(color: Colors.black12),
                            color: Colors.grey.shade200,
                          ),
                          child: const Text(
                            'Nenhuma foto',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      const Spacer(),
                      Padding(
                        padding: EdgeInsets.all(10.0 * widthFactor),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 5 * widthFactor,
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF49D5D2),
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 40 * widthFactor,
                                      vertical: 10 * heightFactor,
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 18 * widthFactor,
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (fotoPath != null) {
                                      await processarImagem();
                                      _confirm = true;
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Uma foto precisa ser anexada para dar andamento ao exame",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text("Enviar"),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 5 * widthFactor,
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF49D5D2),
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 40 * widthFactor,
                                      vertical: 10 * heightFactor,
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 18 * widthFactor,
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (fotoPath != null && _confirm == true) {
                                      _confirm = false;
                                      await reqRacoes();
                                      if (_confirm2 == true) {
                                        _confirm2 = false;
                                        Navigator.pop(context, {
                                          'boxes': boxes,
                                          'racoes': racoes,
                                        });
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Erro ao retornar as recomendações",
                                            ),
                                          ),
                                        );
                                      }
                                    } else if (fotoPath != null &&
                                        _confirm == false) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Antes de finalizar é necessário enviar a foto para a IA analisar",
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Uma foto precisa ser anexada para dar andamento ao exame",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text("Finalizar"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CapturaCamera extends StatefulWidget {
  const CapturaCamera({Key? key}) : super(key: key);

  @override
  State<CapturaCamera> createState() => _CapturaCameraState();
}

class _CapturaCameraState extends State<CapturaCamera>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;
      _initFuture = controller.initialize();
      setState(() {});
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar câmera: $erro')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Câmera', style: TextStyle(fontSize: 20 * widthFactor)),
        centerTitle: true,
      ),
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      Center(child: CameraPreview(controller)),
                      Positioned(
                        bottom: 32 * heightFactor,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: EdgeInsets.all(18 * widthFactor),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              try {
                                await _initFuture;
                                final file = await controller.takePicture();
                                if (!mounted) return;
                                Navigator.pop(context, file.path);
                              } catch (erro) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Falha ao tirar foto: $erro'),
                                  ),
                                );
                              }
                            },
                            child: Icon(
                              Icons.camera_alt,
                              size: 32 * widthFactor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro: ${snapshot.error}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * widthFactor,
                      ),
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
}

class Account extends StatefulWidget {
  const Account({Key? key}) : super(key: key);

  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('image/backgrounddp.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30 * widthFactor),
                child: Container(
                  width: 320 * widthFactor,
                  height: 500 * heightFactor,
                  padding: EdgeInsets.all(20 * widthFactor),
                  color: Colors.white.withValues(alpha: 0.9),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 50 * widthFactor,
                            backgroundImage: AssetImage(
                              'image/dermapetsupport.jpeg',
                            ),
                          ),
                          SizedBox(height: 15 * heightFactor),
                          Text(
                            nomeVeterinario ?? "Usuário Atual",
                            style: TextStyle(
                              fontSize: 22 * widthFactor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),
                          const Text(
                            "CRMV-SP12345",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF49D5D2),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20 * widthFactor,
                                vertical: 10 * heightFactor,
                              ),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Abrindo suporte via WhatsApp...",
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text("Fale conosco"),
                          ),
                          SizedBox(height: 15 * heightFactor),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 40 * widthFactor,
                                vertical: 10 * heightFactor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              idVeterinario = null;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => Login()),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              "Sair da conta",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.facebook, size: 30, color: Colors.blue),
                          SizedBox(width: 25),
                          Icon(
                            Icons.camera_alt,
                            size: 30,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetalhesLaudo extends StatefulWidget {
  final Laudo laudo;
  DetalhesLaudo({required this.laudo, Key? key}) : super(key: key);
  @override
  _DetalhesLaudoState createState() => _DetalhesLaudoState();
}

class _DetalhesLaudoState extends State<DetalhesLaudo> {
  TextEditingController observacaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    observacaoController.text = widget.laudo.observacao ?? '';
  }

  //Gerar PDF
  Future<Uint8List> generatePdf(String observacao) async {
    final pdf = pw.Document();
    List<dynamic> ali = jsonDecode(widget.laudo.alimentos);
    List<dynamic> alo = jsonDecode(widget.laudo.racoes);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Laudo - Exame Dermatológico',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),

              pw.SizedBox(height: 24),

              pw.Text(
                'Dados do Paciente:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.Text(
                'Animal: ${widget.laudo.animal}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Sexo: ${widget.laudo.sexo}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Peso: ${widget.laudo.peso}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Data do Exame: ${formatarData(widget.laudo.data)}',
                style: pw.TextStyle(fontSize: 14),
              ),

              pw.Text("Exame:", style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 8),
              ...ali.where((e) => e['name'] != "Sem nome").map((e) {
                final nome = e['name'];
                final veri = e['veri'] == 0 ? "Não contem." : "Contem.";
                return pw.Text(
                  "- $nome : $veri",
                  style: pw.TextStyle(fontSize: 14),
                );
              }).toList(),

              pw.SizedBox(height: 8),
              ...alo.map((e) {
                final nome = e['nome'];
                final marca = e['marca'];
                final mensagem = e['mensagem'];
                return pw.Text(
                  "Racao: $nome, "
                  "Marca da ração: $marca, "
                  "Motivo: $mensagem ",
                  style: pw.TextStyle(fontSize: 14),
                );
              }).toList(),

              pw.SizedBox(height: 24),
              // OBSERVAÇÕES
              pw.Text(
                'Observações:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.Text(
                observacao.isNotEmpty
                    ? observacao
                    : 'Nenhuma observação registrada.',
                style: pw.TextStyle(fontSize: 14),
              ),

              pw.Spacer(),
              pw.Text(
                'Assinatura do(a) Veterinário(a): _______________________________',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 10),

              pw.Text(
                'CRMV-SP 12345',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  //Salvar pdf
  Future<void> savePdfToDownloads(Uint8List pdfBytes) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception("Permissão de armazenamento não concedida");
          }
        }
      }

      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final filePath =
          '${downloadsDir.path}/laudo_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      await file.writeAsBytes(pdfBytes);

      await OpenFile.open(file.path);
      debugPrint('PDF salvo em: ${file.path}');
    } catch (e) {
      debugPrint('Erro ao salvar PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    final listaalimentos = jsonDecode(widget.laudo.alimentos);

    final alergias = listaalimentos
        .where((a) => a["name"] != "Sem nome" && a["veri"] == 1)
        .map((a) => a["name"])
        .join(", ");

    final listaracoes = jsonDecode(widget.laudo.racoes);

    final racoes = listaracoes.map((a) => a['nome']).join(", ");

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('image/backgrounddp.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          //foreground
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30 * widthFactor),
                child: Container(
                  height: 880.0 * heightFactor,
                  width: 345.0 * widthFactor,
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(height: 50 * heightFactor),
                      Text(
                        'Detalhes do Exame ',
                        style: TextStyle(fontSize: 30 * widthFactor),
                      ),
                      SizedBox(height: 50 * heightFactor),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                // Dono
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    40 * widthFactor,
                                  ),
                                  child: Container(
                                    height: 40 * heightFactor,
                                    width: 160 * widthFactor,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      'Dono: ${widget.laudo.dono}',
                                      style: TextStyle(
                                        fontSize: 13 * widthFactor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10 * heightFactor),

                                // Animal
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    40 * widthFactor,
                                  ),
                                  child: Container(
                                    height: 40 * heightFactor,
                                    width: 160 * widthFactor,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      'Animal: ${widget.laudo.animal}',
                                      style: TextStyle(
                                        fontSize: 13 * widthFactor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10 * heightFactor),

                                // Sexo
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    40 * widthFactor,
                                  ),
                                  child: Container(
                                    height: 40 * heightFactor,
                                    width: 160 * widthFactor,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      'Sexo do animal: ${widget.laudo.sexo}',
                                      style: TextStyle(
                                        fontSize: 13 * widthFactor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10 * heightFactor),

                                // Peso
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    40 * widthFactor,
                                  ),
                                  child: Container(
                                    height: 40 * heightFactor,
                                    width: 160 * widthFactor,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      'Peso do animal: ${widget.laudo.peso}',
                                      style: TextStyle(
                                        fontSize: 13 * widthFactor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10 * heightFactor),

                                // Data
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    40 * widthFactor,
                                  ),
                                  child: Container(
                                    height: 40 * heightFactor,
                                    width: 160 * widthFactor,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      'Data: ${formatarData(widget.laudo.data)}',
                                      style: TextStyle(
                                        fontSize: 13 * widthFactor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 5 * widthFactor),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                // Resultado exame
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    40 * widthFactor,
                                  ),
                                  child: Container(
                                    height: 240 * heightFactor,
                                    width: 160 * widthFactor,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      'Alergias: $alergias',
                                      style: TextStyle(
                                        fontSize: 12 * widthFactor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20 * heightFactor),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                //Resultado recomendações
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    40 * widthFactor,
                                  ),
                                  child: Container(
                                    height: 250 * heightFactor,
                                    width: 160 * widthFactor,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      'Rações recomendadas: $racoes',
                                      style: TextStyle(
                                        fontSize: 12 * widthFactor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 5 * widthFactor),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                // Observação
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    26 * widthFactor,
                                  ),
                                  child: Container(
                                    height: 250 * heightFactor,
                                    width: 160 * widthFactor,
                                    color: Colors.grey[300],
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.only(
                                      left: 12 * widthFactor,
                                    ),
                                    child: TextField(
                                      controller: observacaoController,
                                      maxLines: null,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Adicione observações caso seja necessário: ',
                                        border: InputBorder.none,
                                        isCollapsed: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: 15 * widthFactor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      // Botões
                      Padding(
                        padding: EdgeInsets.all(9.0 * widthFactor),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF49D5D2),
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 3 * heightFactor,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 13 * widthFactor,
                                  ),
                                ),
                                onPressed: () async {
                                  setState(() {
                                    widget.laudo.observacao =
                                        observacaoController.text;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'PDF gerado! Abrindo visualização',
                                      ),
                                    ),
                                  );
                                  final observacao =
                                      widget.laudo.observacao ?? '';
                                  final pdfData = await generatePdf(observacao);
                                  await savePdfToDownloads(pdfData);
                                  await Printing.layoutPdf(
                                    onLayout: (PdfPageFormat format) async =>
                                        pdfData,
                                  );
                                },
                                child: const Text("Baixar PDF"),
                              ),
                            ),
                            SizedBox(width: 10 * widthFactor),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF49D5D2),
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 3 * heightFactor,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 13 * widthFactor,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Voltar"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClienteDetalhes extends StatelessWidget {
  final Clientes cliente;
  final List<Laudo> laudos;
  final List<Clientes> cadastro;

  const ClienteDetalhes({
    required this.cliente,
    required this.laudos,
    required this.cadastro,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final laudosDoCliente = laudos
        .where((l) => l.clienteid == cliente.id)
        .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthFactor = screenWidth / 360;
    final heightFactor = screenHeight / 808;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('image/backgrounddp2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30 * widthFactor),
                child: Column(
                  children: [
                    SizedBox(height: 20 * heightFactor),
                    Text(
                      'Laudos',
                      style: TextStyle(
                        fontSize: 24 * widthFactor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20 * heightFactor),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * widthFactor,
                        ),
                        child: laudosDoCliente.isEmpty
                            ? Center(
                                child: Text(
                                  'Nenhum exame cadastrado para este cliente.',
                                  style: TextStyle(fontSize: 16 * widthFactor),
                                ),
                              )
                            : GridView.builder(
                                itemCount: laudosDoCliente.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12 * widthFactor,
                                      mainAxisSpacing: 12 * heightFactor,
                                      childAspectRatio: 3 / 2,
                                    ),
                                itemBuilder: (context, index) {
                                  final laudo = laudosDoCliente[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DetalhesLaudo(laudo: laudo),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12 * widthFactor,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          8.0 * widthFactor,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Exame: ${index + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16 * widthFactor,
                                              ),
                                            ),
                                            SizedBox(height: 4 * heightFactor),
                                            Text(
                                              'Animal: ${laudo.animal}',
                                              style: TextStyle(
                                                fontSize: 14 * widthFactor,
                                              ),
                                            ),
                                            SizedBox(height: 4 * heightFactor),
                                            Text(
                                              'Data: ${formatarData(laudo.data)}',
                                              style: TextStyle(
                                                fontSize: 14 * widthFactor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    // Botão
                    Padding(
                      padding: EdgeInsets.only(bottom: 20.0 * heightFactor),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF49D5D2),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: 30 * widthFactor,
                            vertical: 10 * heightFactor,
                          ),
                          textStyle: TextStyle(fontSize: 14 * widthFactor),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PreencherInfos(
                                cadastro: cadastro,
                                cards: laudos,
                                fotos: [],
                                clienteSelecionado: cliente,
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        },
                        child: Text("Novo Exame"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
