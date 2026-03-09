
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class DropdownSearchWidget<T> extends StatelessWidget {
  final DropdownSearchOnFind<T> itemValueBuilder;
  final ValueChanged<T?>? onChangedFn;
  final FormFieldValidator<T>? validator;
  final DropdownSearchPopupItemBuilder<T>? popupItemBuilder;
  final DropdownSearchBuilder<T>? dropItemBuilder;
  final BuildContext context;
  final DropdownSearchCompareFn<T>? compareFn;
  final Widget label;
  final TextStyle baseStyle;


  const DropdownSearchWidget({
    super.key,
    required this.itemValueBuilder, 
    required this.popupItemBuilder, 
    this.dropItemBuilder, 
    required this.context, 
    this.compareFn, 
    required this.label, 
    required this.onChangedFn, 
    required this.baseStyle, 
    this.validator,
  });
  
  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>(
      items: itemValueBuilder,
      compareFn: compareFn ?? (item1, item2) => item1 == item2,
      // itemAsString: (item) => item.$2.name!,
      suffixProps: DropdownSuffixProps(
          dropdownButtonProps: DropdownButtonProps(
              iconClosed: Icon(Icons.keyboard_arrow_down),
              iconOpened: Icon(Icons.keyboard_arrow_up))),
      decoratorProps: DropDownDecoratorProps(
          baseStyle: baseStyle,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            label: label,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
            // hintText: 'Please choose family...'
          )),
      dropdownBuilder: dropItemBuilder,
      popupProps: PopupProps.menu(
        itemBuilder: popupItemBuilder,
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
              decoration: InputDecoration(icon: Icon(Icons.search))),
        constraints: BoxConstraints(maxHeight: 260),
        menuProps: MenuProps(
          margin: EdgeInsets.only(top: 12),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(12))),
        ),
      ),
      onChanged: onChangedFn,
      validator: validator,
    );
  }

}

