// このファイルは Ruby (Opal) から React / React Native / Expo モジュールへ
// 到達するための唯一の入口。ここで __RN__ グローバルに JS を置いてから、
// Ruby バンドルを require する。業務ロジックも UI もここには書かない。

import * as React from 'react';
import {
  Alert,
  BackHandler,
  FlatList,
  Image,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import {
  SafeAreaProvider,
  useSafeAreaInsets,
} from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as SQLite from 'expo-sqlite';

type Bridge = {
  React: typeof React;
  RN: {
    View: typeof View;
    Text: typeof Text;
    Image: typeof Image;
    FlatList: typeof FlatList;
    ScrollView: typeof ScrollView;
    Pressable: typeof Pressable;
    TextInput: typeof TextInput;
    StyleSheet: typeof StyleSheet;
    Modal: typeof Modal;
    KeyboardAvoidingView: typeof KeyboardAvoidingView;
    platformOS: typeof Platform.OS;
  };
  Expo: {
    StatusBar: typeof StatusBar;
    SafeAreaProvider: typeof SafeAreaProvider;
    useSafeAreaInsets: typeof useSafeAreaInsets;
    Ionicons: typeof Ionicons;
  };
  /** Tiny helpers Ruby uses for OS-level UI that isn't a component. */
  UI: {
    confirm: (
      title: string,
      message: string,
      okLabel: string,
      cancelLabel: string,
      onOk: () => void,
    ) => void;
    /**
     * Subscribe to the Android hardware back press. `handler` returns true
     * when it consumed the event (so RN's default exit-the-app behaviour is
     * suppressed); return false to let it fall through. The returned
     * function removes the listener.
     */
    addBackHandler: (handler: () => boolean) => () => void;
  };
  SQLite: {
    open: (name: string) => SQLite.SQLiteDatabase;
    /** Execute a statement without returning rows. */
    exec: (db: SQLite.SQLiteDatabase, sql: string) => void;
    /** Run a prepared statement with parameters; returns change metadata. */
    run: (
      db: SQLite.SQLiteDatabase,
      sql: string,
      params: unknown[],
    ) => { changes: number; lastInsertRowId: number };
    /** Return every row as a plain JS object. */
    all: <T = Record<string, unknown>>(
      db: SQLite.SQLiteDatabase,
      sql: string,
      params: unknown[],
    ) => T[];
  };
  /** Ruby 側が `__RN__.setRoot(fn)` で設定する。 */
  setRoot: (fn: React.ComponentType<unknown>) => void;
  getRoot: () => React.ComponentType<unknown> | null;
};

const g = globalThis as unknown as { __RN__?: Bridge };

if (!g.__RN__) {
  let root: React.ComponentType<unknown> | null = null;
  g.__RN__ = {
    React,
    RN: {
      View,
      Text,
      Image,
      FlatList,
      ScrollView,
      Pressable,
      TextInput,
      StyleSheet,
      Modal,
      KeyboardAvoidingView,
      platformOS: Platform.OS,
    },
    Expo: {
      StatusBar,
      SafeAreaProvider,
      useSafeAreaInsets,
      Ionicons,
    },
    UI: {
      confirm: (title, message, okLabel, cancelLabel, onOk) => {
        Alert.alert(title, message, [
          { text: cancelLabel, style: 'cancel' },
          { text: okLabel, style: 'destructive', onPress: onOk },
        ]);
      },
      addBackHandler: (handler) => {
        const sub = BackHandler.addEventListener(
          'hardwareBackPress',
          handler,
        );
        return () => sub.remove();
      },
    },
    SQLite: {
      open: (name) => SQLite.openDatabaseSync(name),
      exec: (db, sql) => {
        db.execSync(sql);
      },
      run: (db, sql, params) => {
        const stmt = db.prepareSync(sql);
        try {
          const res = stmt.executeSync(params);
          return {
            changes: res.changes,
            lastInsertRowId: Number(res.lastInsertRowId),
          };
        } finally {
          stmt.finalizeSync();
        }
      },
      all: (db, sql, params) => {
        const stmt = db.prepareSync(sql);
        try {
          const res = stmt.executeSync(params);
          return res.getAllSync() as never;
        } finally {
          stmt.finalizeSync();
        }
      },
    },
    setRoot: (fn) => {
      root = fn;
    },
    getRoot: () => root,
  };
}

// Side-effect: load the Opal bundle AFTER __RN__ is set. We use require()
// instead of `import` because ES module imports are hoisted above the
// __RN__ assignment above, which would cause the bundle to blow up with
// `Property '__RN__' doesn't exist`.
// eslint-disable-next-line @typescript-eslint/no-require-imports
require('./ruby-generated/xapp');

export const Bridge = g.__RN__!;

export const RubyRoot: React.FC = () => {
  const Root = Bridge.getRoot();
  if (!Root) {
    throw new Error(
      'Ruby 側 (XApp::UI) から __RN__.setRoot が呼ばれていません。' +
        ' ruby/xapp/ui/register.rb が require されているか確認してください。',
    );
  }
  return React.createElement(Root, null);
};
