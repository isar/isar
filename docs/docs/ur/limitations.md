# حدود 

جیسا کہ آپ جانتے ہیں، ای زار ورچوئل مشین کے ساتھ ساتھ ویب پر چلنے والے موبائل آلات اور ڈیسک ٹاپس پر کام کرتا ہے۔ دونوں پلیٹ فارم بہت مختلف ہیں اور مختلف حدود ہیں۔

## وی ایم حدود

- کسی سٹرنگ کے صرف پہلے 1024 بائٹس کو ایک سابقہ ​​جہاں-شق کے لیے استعمال کیا جا سکتا ہے۔
- اشیاء صرف 16MB سائز کی ہو سکتی ہیں۔

## ویب کی حدود

چونکہ  ای زار ویب انڈیکس دیٹا بیس پر انحصار کرتا ہے، اس لیے مزید حدود ہیں لیکن ای زار استعمال کرتے وقت وہ بمشکل ہی قابل توجہ ہیں۔

- Synchronous methods are unsupported
- Currently, `Isar.splitWords()` and `.matches()` filters are not yet implemented
- Schema changes are not as tighly checked as in the VM so be careful to comply with the rules
- All number types are stored as double (the only js number type) so `@Size32` has no effect
- Indexes are represented differenlty so hash indexes don't use less space (they still work the same)
- `col.delete()` and `col.deleteAll()` work correctly but the return value is not correct
- `col.clear()` do not reset the auto-increment value
- `NaN` is not supported as a value
