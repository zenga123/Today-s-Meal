 ## 開発環境と実行手順

本プロジェクトをローカル環境でセットアップし、実行するための手順は以下の通りです。

### 必要なもの

*   **macOS**
*   **Xcode 15.2** 以降
    *   App Store または [Apple Developerウェブサイト](https://developer.apple.com/jp/xcode/) からインストールしてください。
*   **CocoaPods**
    *   インストールされていない場合は、ターミナルで以下のコマンドを実行してインストールしてください。
        ```bash
        sudo gem install cocoapods
        ```

### セットアップ手順

1.  **リポジトリをクローン:**
    ターミナルを開き、任意のディレクトリで以下のコマンドを実行して、本プロジェクトのリポジトリをクローンします。
    ```bash
    git clone [プロジェクトのGitHubリポジトリURL]
    cd [クローンしたプロジェクトのディレクトリ名] # 例: cd Today-s-Meal
    ```
    *   `[プロジェクトのGitHubリポジトリURL]` と `[クローンしたプロジェクトのディレクトリ名]` は、実際の値に置き換えてください。

2.  **依存ライブラリのインストール:**
    プロジェクトのルートディレクトリ（`Podfile` が存在するディレクトリ）で、以下のコマンドを実行して依存ライブラリをインストールします。
    ```bash
    pod install
    ```
    これにより、`[プロジェクト名].xcworkspace` ファイルが生成（または更新）されます。

3.  **Google Maps API キーの設定:**
    本プロジェクトでは地図機能に Google Maps Platform の SDK を利用しており、実行には API キーの設定が必要です。具体的には以下の2つの API を利用しています。
    *   **Maps SDK for iOS:** アプリの主要なネイティブ地図表示（店舗検索画面など）に使用します。
    *   **Maps JavaScript API:** 店舗詳細画面の経路表示機能（`WKWebView` 内）に使用します。

    *   **API キーの取得と設定:**
        1.  **Google Cloud Platform Console で API を有効化:**
            *   Google Cloud Platform Console にて、ご自身のプロジェクトで以下の2つの API を有効にしてください。
                *   **Maps SDK for iOS**
                *   **Maps JavaScript API**
        2.  **API キーの作成と制限:**
            *   有効化した API を使用するための API キーを作成します。
    *   **API キーの設定箇所:**
        取得した API キーを、プロジェクト内の `Today-s-Meal/AppDelegate.swift` ファイルに設定します。
        具体的には、`AppDelegate.swift` ファイル内の `application(_:didFinishLaunchingWithOptions:)` メソッドで `GMSServices.provideAPIKey()` を呼び出している箇所を以下のように修正します。

        ```swift
        import UIKit
        import GoogleMaps // ファイル上部に追加

        let googleApiKey = "ここにGoogle Maps APIキーを入力してください"

        let hotPepperApiKey = "ここにホットペッパーAPIキーを入力してください"

        ```
        上記コードの "ここにGoogle Maps APIキーを入力してください" の部分を、実際に取得した Google Maps API キーに置き換えてください。同様に、"ここにホットペッパーAPIキーを入力してください" の部分を、実際に取得したホットペッパーAPIキーに置き換えてください。

4.  **ホットペッパーグルメサーチ API キーの設定:**
    本プロジェクトでは、店舗情報の検索に「ホットペッパーグルメサーチAPI」を利用しています。この API を利用するためにも API キーが必要です。

    *   **API キーの取得:**
        1.  リクルートWEBサービス ([https://webservice.recruit.co.jp/](https://webservice.recruit.co.jp/)) にアクセスし、新規登録またはログインします。
        2.  APIキー発行の手続きを行い、「ホットペッパーグルメサーチAPI」用の API キーを取得します。
        3.  詳細な利用方法や規約については、ホットペッパーAPIリファレンス ([https://webservice.recruit.co.jp/doc/hotpepper/reference.html](https://webservice.recruit.co.jp/doc/hotpepper/reference.html)) を参照してください。

    *   **API キーのプロジェクトへの設定:**
        取得した API キーを、プロジェクト内の `Today-s-Meal/AppDelegate.swift` ファイル上部にある `hotPepperApiKey` 定数に設定してください。
        ```swift
        // ... (googleApiKey の定義) ...

        let hotPepperApiKey = "YOUR_ACTUAL_HOTPEPPER_API_KEY" // TODO: 取得したホットペッパーAPIキーに置き換えてください

        @main
        class AppDelegate: UIResponder, UIApplicationDelegate {
        // ... (以下同様)
        ```
        `"YOUR_ACTUAL_HOTPEPPER_API_KEY"` の部分を、実際に取得したホットペッパーAPIキーに置き換えてください。

5.  **プロジェクトを開く:**
    Finder でプロジェクトのディレクトリを開き、`[プロジェクト名].xcodeproj` ファイルではなく、**`[プロジェクト名].xcworkspace`** ファイルをダブルクリックして Xcode でプロジェクトを開いてください。

6.  **ビルドと実行:**
    *   Xcode の画面上部にあるターゲット選択メニューから、実行するシミュレータまたは接続されている実機を選択します。
    *   Xcode の左上にある実行ボタン（▶︎ アイコン）をクリックするか、キーボードショートカット `Cmd + R` を押して、アプリをビルドし実行します。

ご不明な点がありましたら、お気軽にお問い合わせください。

 ## アプリ実行画面

 
