// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_dartlang_org.handlers_test;

import 'dart:async';

import 'package:pub_dartlang_org/shared/search_client.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import 'package:pub_dartlang_org/frontend/backend.dart';
import 'package:pub_dartlang_org/frontend/handlers.dart';
import 'package:pub_dartlang_org/frontend/models.dart';
import 'package:pub_dartlang_org/frontend/search_service.dart';
import 'package:pub_dartlang_org/frontend/templates.dart';
import 'package:pub_dartlang_org/shared/analyzer_client.dart';
import 'package:pub_dartlang_org/shared/search_service.dart';

Future<shelf.Response> issueGet(String path) async {
  final uri = 'https://pub.dartlang.org$path';
  final request = new shelf.Request('GET', Uri.parse(uri));
  return appHandler(request, null);
}

Future expectHtmlResponse(shelf.Response response, {status: 200}) async {
  expect(response.statusCode, status);
  expect(response.headers['content-type'], 'text/html; charset="utf-8"');
  expect(await response.readAsString(), TemplateMock.Response);
}

Future expectAtomXmlResponse(shelf.Response response,
    {int status: 200, String regexp}) async {
  expect(response.statusCode, status);
  expect(response.headers['content-type'],
      'application/atom+xml; charset="utf-8"');
  final text = await response.readAsString();
  expect(new RegExp(regexp).hasMatch(text), isTrue);
}

class BackendMock implements Backend {
  final Function latestPackageVersionsFun;
  final Function latestPackagesFun;
  final Function lookupLatestVersionsFun;
  final Function lookupPackageFun;
  final Function lookupPackageVersionFun;
  final Function versionsOfPackageFun;
  final Function downloadUrlFun;

  BackendMock(
      {this.latestPackageVersionsFun,
      this.latestPackagesFun,
      this.lookupLatestVersionsFun,
      this.lookupPackageFun,
      this.lookupPackageVersionFun,
      this.versionsOfPackageFun,
      this.downloadUrlFun});

  @override
  // ignore: always_declare_return_types
  get db => throw 'unexpected db access';

  @override
  // ignore: always_declare_return_types
  get repository => throw 'unexpected repository access';

  @override
  // ignore: always_declare_return_types
  get uiPackageCache => null;

  @override
  Future<List<PackageVersion>> latestPackageVersions(
      {int offset, int limit, bool devVersions: false}) async {
    if (latestPackageVersionsFun == null) throw 'no latestPackageVersionsFun';
    return latestPackageVersionsFun(offset: offset, limit: limit);
  }

  @override
  Future<List<Package>> latestPackages(
      {int offset, int limit, String detectedType}) async {
    if (latestPackagesFun == null) throw 'no latestPackagesFun';
    return latestPackagesFun(
        offset: offset, limit: limit, detectedType: detectedType);
  }

  @override
  Future<List<PackageVersion>> lookupLatestVersions(List<Package> packages,
      {bool devVersions: false}) async {
    if (lookupLatestVersionsFun == null) throw 'no lookupLatestVersionsFun';
    return lookupLatestVersionsFun(packages);
  }

  @override
  Future<Package> lookupPackage(String packageName) async {
    if (lookupPackageFun == null) throw 'no lookupPackageVersionFun';
    return lookupPackageFun(packageName);
  }

  @override
  Future<List<Package>> lookupPackages(Iterable<String> packageNames) {
    return Future.wait(packageNames.map(lookupPackage));
  }

  @override
  Future<PackageVersion> lookupPackageVersion(
      String package, String version) async {
    if (lookupPackageVersionFun == null) throw 'no lookupPackageVersionFun';
    return lookupPackageVersionFun(package, version);
  }

  @override
  Future<List<PackageVersion>> versionsOfPackage(String packageName) async {
    if (versionsOfPackageFun == null) throw 'no versionsOfPackageFun';
    return versionsOfPackageFun(packageName);
  }

  @override
  Future<Uri> downloadUrl(String package, String version) async {
    if (downloadUrlFun == null) throw 'no downloadUrlFun';
    return downloadUrlFun(package, version);
  }
}

class TemplateMock implements TemplateService {
  static String Response = 'foobar';

  @override
  String get templateDirectory => null;

  @override
  String renderAuthorizedPage() {
    return Response;
  }

  @override
  String renderErrorPage(String status, String message, String traceback) {
    return Response;
  }

  @override
  String renderIndexPage(
      List<PackageVersion> recentPackages, List<AnalysisView> analysisViews) {
    return Response;
  }

  @override
  String renderLayoutPage(String title, String contentString,
      {PackageVersion packageVersion,
      String faviconUrl,
      String searchQuery,
      bool includeSurvey}) {
    return Response;
  }

  @override
  String renderPagination(PageLinks pageLinks) {
    return Response;
  }

  @override
  String renderPkgIndexPage(
      List<Package> packages,
      List<PackageVersion> versions,
      List<AnalysisView> analysisViews,
      PageLinks links,
      {String title,
      String faviconUrl,
      String descriptionHtml}) {
    return Response;
  }

  @override
  String renderPkgShowPage(
      Package package,
      List<PackageVersion> versions,
      List<Uri> versionDownloadUrls,
      PackageVersion selectedVersion,
      PackageVersion latestStableVersion,
      PackageVersion latestDevVersion,
      int totalNumberOfVersions,
      AnalysisView analysis,
      String analysisTabContent) {
    return Response;
  }

  @override
  String renderPkgVersionsPage(String package, List<PackageVersion> versions,
      List<Uri> versionDownloadUrls) {
    return Response;
  }

  @override
  String renderSearchPage(SearchResultPage resultPage, PageLinks pageLinks) {
    return Response;
  }

  @override
  String renderAnalysisTab(analysis) {
    return Response;
  }
}

class SearchClientMock implements SearchClient {
  final Function searchFun;
  SearchClientMock({this.searchFun});

  @override
  Future<PackageSearchResult> search(SearchQuery query) async {
    if (searchFun == null) throw 'no searchFun';
    return searchFun(query);
  }

  @override
  Future close() async {}
}

class SearchServiceMock implements SearchService {
  final Function searchFun;

  SearchServiceMock(this.searchFun);

  @override
  Future<SearchResultPage> search(SearchQuery query) async {
    return searchFun(query);
  }

  @override
  Future close() async => null;
}

class AnalyzerClientMock implements AnalyzerClient {
  AnalysisData mockAnalysisData;

  @override
  Future<AnalysisData> getAnalysisData(String package, String version) async =>
      mockAnalysisData;

  @override
  Future close() async => null;

  @override
  Future<AnalysisView> getAnalysisView(String package, String version) async =>
      new AnalysisView(await getAnalysisData(package, version));
}
