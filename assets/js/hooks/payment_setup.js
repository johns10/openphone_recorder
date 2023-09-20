function publicKey() {
  if (process.env.NODE_ENV === 'development') return `pk_test_51NJe4fD6og6lHPCf1vJQArEk6he5MqGQsUQzQ869Lol4WTBtuVpuhn4GCCx1dZmq9brfD2RvCbWP1c9nj3y8L20N008m18e0zY`
  if (process.env.NODE_ENV === 'production') return 'pk_live_51NJe4fD6og6lHPCfQRWiYjgbPRrjPkiVSoYxu8VbwE6RwLWldQpuTCw0rJUrh8lKa3eakgCi0yRqfqEouA5ckxUW00KUXEkvtc'
}

const stripe = Stripe(publicKey())

export default PaymentSetup = {
  mounted() {
    const successCallback = setupIntent => {
      this.pushEventTo('#payment-element', 'payment-setup', setupIntent)
    }
    init(this.el, successCallback)
  }
}

const init = (form, successCallback) => {
  const clientSecret = form.dataset.secret
  const accountId = form.dataset.accountId
  var elements = stripe.elements({ clientSecret, appearance });
  var payment = elements.create('payment');
  payment.mount('#payment-element');

  payment.on('change', function (event) {
    var displayError = document.getElementById('card-errors');
    if (event.error) {
      document.getElementById('submit-payment').removeAttribute('disabled')
      displayError.textContent = event.error.message;
    } else {
      document.getElementById('submit-payment').removeAttribute('disabled')
      displayError.textContent = '';
    }
  });

  // Handle form submission.
  form.addEventListener('submit', function (event) {
    event.preventDefault()

    stripe.confirmSetup({
      elements,
      confirmParams: { return_url: `${window.location.origin}/accounts/${accountId}` },
      redirect: 'if_required'
    }).then(function (result) {
      if (result.error) {
        console.log(result.error.message);
      } else {
        if (result.setupIntent.status === 'succeeded') {
          successCallback(result.setupIntent)
        }
      }
    })
    document.getElementById("submit-payment").setAttribute("disabled", true)
  })
}

const appearance = {
  theme: 'night'
}