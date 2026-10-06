import 'package:result_rust/result_rust.dart';

Future<void> main() async {
  final result = splitName("Alex Bob");

  // example 1
  switch (result) {
    case Ok(value: final parts):
      print(parts);
      break;
    case Err(error: final errMsg):
      print(errMsg);
      break;
  }

  // example 2
  if (result.isOk()) {
    print("The name: \thas ${result.intoOk().length} parts.");
  }
  if (result.isErr()) {
    print('Something is not right.');

    result.inspect((parts) {
      print(parts);
    });
  }
}

// assumes name in two part
Result<List<String>, String> splitName(String fullName) {
  final List<String> nameParts = fullName.trim().split(' ');
  // name has only one part
  if (nameParts.length <= 1) {
    // a err msg
    return Err("something is wrong");
  }
  return Ok(nameParts);
}
