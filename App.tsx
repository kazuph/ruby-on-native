// 本ファイルは Metro/Expo が要求する唯一の TSX。業務ロジック・UI はここには存在せず、
// すべては Ruby (ruby/xapp/**/*.rb) にあります。消したい場合は index.ts から直接
// RubyRoot を登録してもほぼ同義です。
import React from 'react';
import { RubyRoot } from './src/native-bridge';

export default function App() {
  return <RubyRoot />;
}
