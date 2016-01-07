/* angularjs metaapp
    copyright 2015 monir mamoun
*/

var myMetaApp = angular
.module('metaApp',[
  'ui.router'
  ]);

myMetaApp
.constant('configEndpoint', 'http://www.natex.com/metaapp/config.json')
.factory('Pusher', function($window, $log) {
  var Pusher =  $window.Pusher;
  Pusher.log = $log.info;
  return Pusher;
})
.config(function($stateProvider, $urlRouterProvider,$logProvider) {
  $logProvider.debugEnabled(true);
  //
  // For any unmatched url, redirect to /state1
  $urlRouterProvider.otherwise('/meta');
  //
  // Now set up the states
  $stateProvider
    .state('home', {
      url:'/home',
      templateUrl: 'partials/home.html',
      controller: 'homeController',
      controllerAs: 'Home'
    })
    .state('meta', {
      url:'/meta/:screen',
      templateUrl: 'partials/meta.html',
      controller: 'metaController',
      controllerAs: 'Meta',
      cache: false,
      resolve: {
        storyboard: function(getMetaStoryboard, $log){
          $log.info('RES meta');
          return getMetaStoryboard();
        }
      }
    })
    .state('maintenance', {
      url:'/maintenance',
      templateUrl: 'partials/maintenance.html',
      controller: 'maintenanceController',
      controllerAs: 'Maintenance',
      resolve: {
        storyboard: function(getMetaStoryboard, $log){
          $log.info('RES main');
          return getMetaStoryboard();
        }
      }
    });
})
// read storyboard and boot to launchScreen
.run(function($log, getMetaStoryboard, $state){
  $log.info('running run block, found states:', $state.get());
  getMetaStoryboard().then(function(storyboard){
    if (storyboard.launchScreen) {
      $log.info('run block storyboard:', storyboard);
      $log.info('going to launch screen: ', storyboard.launchScreen);
      $state.go('meta', { screen: storyboard.launchScreen });
    } else {
      throw 'Invalid configuration - No launch screen provided.'
    }
  });
})
.factory('getMetaStoryboard', function($http, $log, $q){
  var storyboardConfig;

  $log.info('get config thing');

  return function(){
    return $http
        .get('https://s3.amazonaws.com/monir/config.json?'+Math.random(), {cache: false})
        .then(function(response) {
          $log.info('GMS got data', response.data);
          storyboardConfig = response.data;
          $log.info('got new storyboard config', storyboardConfig);
          return storyboardConfig;
        });
  }
})
.controller('homeController', function(getConfig, $log){
  this.test = 'Home Test';
  $log.info('home launch screen')
})
.controller('maintenanceController', function($log, $stateParams, storyboard, Pusher, getMetaStoryboard, $state, $timeout){
  var pusher = new Pusher('a071efcffc1c37bb35c7');
  var channel = pusher.subscribe('metaapp_channel');
  channel.bind('maintenance_event', function(data) {
    if (data.message == 'refresh') {
      $timeout(function(){
        $log.info('got non-maintenance(refresh) message');
        // getMetaStoryboard().then(function(storyboard){
        //   if (storyboard.launchScreen) {
        //     $log.info('run block storyboard:', storyboard);
        //     $log.info('going to launch screen: ', storyboard.launchScreen);
            $state.go('meta', { screen: storyboard.launchScreen });
          // } else {
          //   throw 'Invalid configuration - No launch screen provided.'
          // }
        //});
      })
    }
  });

})
.controller('metaController', function($log, $stateParams, storyboard, Pusher, $state, $timeout){
  var self = this;
  $log.info('we on Meta Test Screen: ' + $stateParams.screen, $stateParams, storyboard);
  self.title = 'Meta App Screen ' + $stateParams.screen;
  self.message = storyboard.storyboard[$stateParams.screen].message || "";
  self.messageColor = storyboard.storyboard[$stateParams.screen].messageColor || "000000";
  self.linkToScreens = storyboard.storyboard[$stateParams.screen].linkToScreens;
  $log.info('link to screens: ', self.linkToScreens);

  var pusher = new Pusher('a071efcffc1c37bb35c7');
  var channel = pusher.subscribe('metaapp_channel');
  channel.bind('maintenance_event', function(data) {
    if (data.message == 'maintenance') {
      $timeout(function(){
        $log.info('got maintenance message');
        $state.go('maintenance');
      });
    }
  });
})
