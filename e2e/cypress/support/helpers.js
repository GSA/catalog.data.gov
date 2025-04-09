// Helper functions

cy.helpers = {
  randomSlug: () => {
    return Array.apply(0, Array(5)).map(function() {
      return (function(charset){
        return charset.charAt(Math.floor(Math.random() * charset.length))
      }('abcdefghijklmnopqrstuvwxyz'));
    }).join('')
  }
}
